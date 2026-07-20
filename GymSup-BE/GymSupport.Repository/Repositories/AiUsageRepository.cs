using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class AiUsageRepository : IAiUsageRepository
{
    private readonly IMongoCollection<AiMonthlyBudget> _budgets;
    private readonly IMongoCollection<AiDailyQuota> _quotas;
    private readonly IMongoCollection<AiUsageLog> _logs;

    public AiUsageRepository(MongoDbContext context)
    {
        _budgets = context.AiMonthlyBudgets;
        _quotas = context.AiDailyQuotas;
        _logs = context.AiUsageLogs;
    }

    public async Task<AiMonthlyBudget?> GetMonthlyBudgetAsync(string period)
    {
        return await _budgets.Find(x => x.Id == period).FirstOrDefaultAsync();
    }

    public async Task<decimal> IncrementMonthlySpendAsync(string period, decimal amountUsd)
    {
        var update = Builders<AiMonthlyBudget>.Update
            .Inc(x => x.SpentUsd, amountUsd)
            .Set(x => x.UpdatedAt, DateTime.UtcNow);

        var options = new FindOneAndUpdateOptions<AiMonthlyBudget>
        {
            IsUpsert = true,
            ReturnDocument = ReturnDocument.After
        };

        var result = await _budgets.FindOneAndUpdateAsync<AiMonthlyBudget>(
            x => x.Id == period,
            update,
            options);

        return result.SpentUsd;
    }

    public async Task<AiDailyQuota?> GetDailyQuotaAsync(string userId, string date)
    {
        var id = BuildQuotaId(userId, date);
        return await _quotas.Find(x => x.Id == id).FirstOrDefaultAsync();
    }

    public async Task<int> IncrementDailyQuotaAsync(string userId, string date, string counterField)
    {
        var id = BuildQuotaId(userId, date);

        UpdateDefinition<AiDailyQuota> update = counterField switch
        {
            "Chat" => Builders<AiDailyQuota>.Update.Inc(x => x.ChatCount, 1),
            "Generate" => Builders<AiDailyQuota>.Update.Inc(x => x.GenerateCount, 1),
            "Analyze" => Builders<AiDailyQuota>.Update.Inc(x => x.AnalyzeCount, 1),
            "Evaluate" => Builders<AiDailyQuota>.Update.Inc(x => x.EvaluateCount, 1),
            _ => throw new ArgumentException($"Unknown counter field: {counterField}", nameof(counterField))
        };

        update = update
            .SetOnInsert(x => x.UserId, userId)
            .SetOnInsert(x => x.Date, date);

        var options = new FindOneAndUpdateOptions<AiDailyQuota>
        {
            IsUpsert = true,
            ReturnDocument = ReturnDocument.After
        };

        var result = await _quotas.FindOneAndUpdateAsync<AiDailyQuota>(
            x => x.Id == id,
            update,
            options);

        return counterField switch
        {
            "Chat" => result.ChatCount,
            "Generate" => result.GenerateCount,
            "Evaluate" => result.EvaluateCount,
            _ => result.AnalyzeCount
        };
    }

    public async Task LogUsageAsync(AiUsageLog log)
    {
        await _logs.InsertOneAsync(log);
    }

    private static string BuildQuotaId(string userId, string date) => $"{userId}_{date}";
}
