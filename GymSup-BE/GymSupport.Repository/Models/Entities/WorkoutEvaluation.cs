using System;
using System.Collections.Generic;

namespace GymSupport.Repository.Models.Entities;

/// <summary>
/// Báo cáo đánh giá AI cho một buổi tập đã hoàn thành. Toàn bộ số liệu (Score,
/// Summary, Highlights, Improvements, Recovery, Nutrition) được backend tính
/// toán xác định (deterministic) - AI chỉ viết 4 trường tường thuật cuối cùng
/// (NarrativeSummary/SuggestedNextWorkout/MotivationalMessage + phần diễn giải
/// trong MealSuggestion) dựa trên các số liệu đã có sẵn, không tự tính lại.
/// Được lưu lại trên WorkoutSessionLog để xem lại không tốn thêm lượt gọi AI.
/// </summary>
public class WorkoutEvaluation
{
    public int Score { get; set; }

    public string Grade { get; set; } = "";

    public WorkoutEvaluationSummary Summary { get; set; } = new();

    public WorkoutSessionComparison Comparison { get; set; } = new();

    public List<string> Highlights { get; set; } = new();

    public List<string> Improvements { get; set; } = new();

    public List<MuscleRecoveryStatus> Recovery { get; set; } = new();

    public NutritionRecommendation Nutrition { get; set; } = new();

    public string NarrativeSummary { get; set; } = "";

    public string SuggestedNextWorkout { get; set; } = "";

    public string MotivationalMessage { get; set; } = "";

    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
}

public class WorkoutEvaluationSummary
{
    public int DurationMinutes { get; set; }
    public int ExerciseCount { get; set; }
    public int TotalSets { get; set; }
    public int TotalReps { get; set; }
    public double TotalVolumeKg { get; set; }
    public int EstimatedCalories { get; set; }
}

/// <summary>So sánh buổi tập này với lần gần nhất tập cùng buổi (cùng PlanSessionId,
/// hoặc cùng tên buổi nếu tập tự do không theo plan).</summary>
public class WorkoutSessionComparison
{
    public bool HasPrevious { get; set; }
    public DateTime? PreviousDate { get; set; }
    public double PreviousVolumeKg { get; set; }
    public double VolumeDeltaPercent { get; set; }
    public int PreviousSets { get; set; }
    public int SetsDelta { get; set; }
    public int PreviousDurationMinutes { get; set; }
    public int DurationDeltaMinutes { get; set; }
}

public class MuscleRecoveryStatus
{
    public string MuscleCategory { get; set; } = "";
    public string Status { get; set; } = "";
    public int RecoveryHours { get; set; }
    public DateTime ReadyAt { get; set; }
}

public class NutritionRecommendation
{
    public int ProteinGrams { get; set; }
    public double WaterLiters { get; set; }
    public string MealSuggestion { get; set; } = "";
}
