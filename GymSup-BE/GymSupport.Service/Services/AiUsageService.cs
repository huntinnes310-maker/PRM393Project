using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.AIModel;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;
using Microsoft.Extensions.Configuration;

namespace GymSupport.Service.Services;

public class AiUsageService : IAiUsageService
{
    private readonly IAiUsageRepository _usageRepository;
    private readonly ISubscriptionService _subscriptionService;
    private readonly IConfiguration _configuration;

    // Giá tham khảo USD / 1 triệu token theo bảng giá OpenAI tại thời điểm viết code.
    // Giá OpenAI có thể thay đổi - hãy đối chiếu lại https://openai.com/api/pricing/
    // và cập nhật qua cấu hình "AiUsage:Pricing:<model>:InputPer1M/OutputPer1M" nếu cần,
    // không cần sửa code.
    private static readonly Dictionary<string, (decimal InputPer1M, decimal OutputPer1M)> DefaultPricing =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["gpt-4o-mini"] = (0.15m, 0.60m),
            ["gpt-4.1-mini"] = (0.40m, 1.60m),
        };

    public AiUsageService(
        IAiUsageRepository usageRepository,
        ISubscriptionService subscriptionService,
        IConfiguration configuration)
    {
        _usageRepository = usageRepository;
        _subscriptionService = subscriptionService;
        _configuration = configuration;
    }

    public async Task<AiUsageCheckResult> CheckAndReserveAsync(string userId, AiFeature feature)
    {
        var isPremium = await IsPremiumAsync(userId);

        // 1. Chat: ai cũng dùng được. Generate/Analyze: chỉ Premium.
        if (!isPremium && feature != AiFeature.Chat)
        {
            return AiUsageCheckResult.Deny(
                "PREMIUM_REQUIRED",
                "Tính năng này chỉ dành cho hội viên Premium.");
        }

        // 2. Cầu dao ngân sách tổng - kiểm tra trước tiên vì đây là giới hạn cứng bảo vệ ví tiền thật,
        // độc lập với quota riêng của từng user.
        var period = DateTime.UtcNow.ToString("yyyy-MM");
        var budget = await _usageRepository.GetMonthlyBudgetAsync(period);
        var capUsd = GetMonthlyBudgetCapUsd();

        if (budget != null && budget.SpentUsd >= capUsd)
        {
            return AiUsageCheckResult.Deny(
                "BUDGET_EXHAUSTED",
                "Hệ thống AI đã đạt giới hạn ngân sách của tháng này. Vui lòng quay lại vào tháng sau.");
        }

        // 3. Quota riêng theo ngày - công bằng giữa các user, tách biệt với cầu dao tổng.
        var date = DateTime.UtcNow.ToString("yyyy-MM-dd");
        var quota = await _usageRepository.GetDailyQuotaAsync(userId, date);

        var (currentCount, limit, counterField) = feature switch
        {
            AiFeature.Chat => (
                quota?.ChatCount ?? 0,
                isPremium ? GetLimit("PremiumChatDailyLimit", 100) : GetLimit("FreeChatDailyLimit", 30),
                "Chat"),
            AiFeature.GenerateWorkoutPlan => (
                quota?.GenerateCount ?? 0,
                GetLimit("PremiumGenerateDailyLimit", 5),
                "Generate"),
            AiFeature.EvaluateWorkout => (
                quota?.EvaluateCount ?? 0,
                GetLimit("PremiumEvaluateDailyLimit", 5),
                "Evaluate"),
            _ => (
                quota?.AnalyzeCount ?? 0,
                GetLimit("PremiumAnalyzeDailyLimit", 15),
                "Analyze"),
        };

        if (currentCount >= limit)
        {
            return AiUsageCheckResult.Deny(
                "DAILY_LIMIT_REACHED",
                $"Bạn đã dùng hết {limit} lượt hôm nay cho tính năng này. Vui lòng quay lại vào ngày mai.");
        }

        // Giữ chỗ ngay trước khi gọi OpenAI để một request lỗi/bị retry liên tục không thể lách quota.
        await _usageRepository.IncrementDailyQuotaAsync(userId, date, counterField);

        return AiUsageCheckResult.Allow();
    }

    public async Task RecordCostAsync(string userId, AiFeature feature, string model, int promptTokens, int completionTokens)
    {
        var pricing = GetPricing(model);

        var cost =
            (promptTokens / 1_000_000m) * pricing.InputPer1M +
            (completionTokens / 1_000_000m) * pricing.OutputPer1M;

        var period = DateTime.UtcNow.ToString("yyyy-MM");
        await _usageRepository.IncrementMonthlySpendAsync(period, cost);

        await _usageRepository.LogUsageAsync(new AiUsageLog
        {
            UserId = userId,
            Feature = feature.ToString(),
            Model = model,
            PromptTokens = promptTokens,
            CompletionTokens = completionTokens,
            CostUsd = cost,
            CreatedAt = DateTime.UtcNow
        });
    }

    public async Task<AiUsageSnapshotDto> GetUsageSnapshotAsync(string userId)
    {
        var isPremium = await IsPremiumAsync(userId);

        var period = DateTime.UtcNow.ToString("yyyy-MM");
        var budget = await _usageRepository.GetMonthlyBudgetAsync(period);
        var capUsd = GetMonthlyBudgetCapUsd();
        var budgetExhausted = budget != null && budget.SpentUsd >= capUsd;

        var date = DateTime.UtcNow.ToString("yyyy-MM-dd");
        var quota = await _usageRepository.GetDailyQuotaAsync(userId, date);

        return new AiUsageSnapshotDto
        {
            IsPremium = isPremium,
            Chat = new AiUsageQuotaDto
            {
                Used = quota?.ChatCount ?? 0,
                Limit = isPremium ? GetLimit("PremiumChatDailyLimit", 100) : GetLimit("FreeChatDailyLimit", 30)
            },
            Generate = new AiUsageQuotaDto
            {
                Used = quota?.GenerateCount ?? 0,
                Limit = GetLimit("PremiumGenerateDailyLimit", 5)
            },
            Analyze = new AiUsageQuotaDto
            {
                Used = quota?.AnalyzeCount ?? 0,
                Limit = GetLimit("PremiumAnalyzeDailyLimit", 15)
            },
            Evaluate = new AiUsageQuotaDto
            {
                Used = quota?.EvaluateCount ?? 0,
                Limit = GetLimit("PremiumEvaluateDailyLimit", 5)
            },
            BudgetExhausted = budgetExhausted
        };
    }

    private async Task<bool> IsPremiumAsync(string userId)
    {
        // Cùng một nguồn sự thật với PremiumOnlyFilter và /api/subscriptions/me.
        var subscription = await _subscriptionService.GetUserCurrentSubscriptionAsync(userId);
        return subscription?.IsPremium ?? false;
    }

    private (decimal InputPer1M, decimal OutputPer1M) GetPricing(string model)
    {
        var configuredInput = GetDecimalConfig($"AiUsage:Pricing:{model}:InputPer1M");
        var configuredOutput = GetDecimalConfig($"AiUsage:Pricing:{model}:OutputPer1M");

        if (configuredInput.HasValue && configuredOutput.HasValue)
        {
            return (configuredInput.Value, configuredOutput.Value);
        }

        return DefaultPricing.TryGetValue(model, out var pricing)
            ? pricing
            : (InputPer1M: 0.50m, OutputPer1M: 1.50m);
    }

    private decimal GetMonthlyBudgetCapUsd() =>
        GetDecimalConfig("AiUsage:MonthlyBudgetUsd") ?? 20m;

    private int GetLimit(string key, int fallback) =>
        GetIntConfig($"AiUsage:{key}") ?? fallback;

    private decimal? GetDecimalConfig(string key) =>
        decimal.TryParse(_configuration[key], out var value) ? value : null;

    private int? GetIntConfig(string key) =>
        int.TryParse(_configuration[key], out var value) ? value : null;
}
