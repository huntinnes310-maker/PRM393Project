using GymSupport.Repository.Models.DTOs.AIModel;

namespace GymSupport.Service.Interfaces;

public enum AiFeature
{
    Chat,
    GenerateWorkoutPlan,
    AnalyzeImage,
    AnalyzeFormVideo,
    EvaluateWorkout
}

public class AiUsageCheckResult
{
    public bool Allowed { get; set; }

    public string? Code { get; set; }

    public string? Message { get; set; }

    public static AiUsageCheckResult Allow() => new() { Allowed = true };

    public static AiUsageCheckResult Deny(string code, string message) =>
        new() { Allowed = false, Code = code, Message = message };
}

public interface IAiUsageService
{
    /// <summary>
    /// Kiểm tra quyền Premium, ngân sách tổng và quota ngày. Nếu cho phép, tự động
    /// giữ chỗ (tăng bộ đếm quota ngày) trước khi gọi OpenAI để tránh lạm dụng qua retry.
    /// </summary>
    Task<AiUsageCheckResult> CheckAndReserveAsync(string userId, AiFeature feature);

    /// <summary>Ghi nhận chi phí thực tế sau khi OpenAI trả về, dựa trên số token đã dùng.</summary>
    Task RecordCostAsync(string userId, AiFeature feature, string model, int promptTokens, int completionTokens);

    Task<AiUsageSnapshotDto> GetUsageSnapshotAsync(string userId);
}
