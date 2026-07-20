using GymSupport.Repository.Models.Entities;

namespace GymSupport.Service.Interfaces;

public interface IWorkoutEvaluationService
{
    /// <summary>
    /// Trả về báo cáo đánh giá AI cho một buổi tập đã hoàn thành (Premium).
    /// Nếu đã có báo cáo được lưu từ trước, trả lại ngay không gọi AI lần nữa.
    /// </summary>
    Task<(AiUsageCheckResult check, WorkoutEvaluation? evaluation)> EvaluateAsync(
        string sessionLogId,
        string userId);
}
