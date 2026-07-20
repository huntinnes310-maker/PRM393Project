namespace GymSupport.Repository.Models.DTOs.AIModel;

/// <summary>
/// Số liệu đã tính toán xong (deterministic), gửi cho AI để AI CHỈ viết phần
/// tường thuật - không tự tính lại hay bịa số liệu.
/// </summary>
public class WorkoutEvaluationMetricsDto
{
    public string Focus { get; set; } = "";
    public int Score { get; set; }
    public string Grade { get; set; } = "";
    public int DurationMinutes { get; set; }
    public int ExerciseCount { get; set; }
    public int TotalSets { get; set; }
    public int TotalReps { get; set; }
    public double TotalVolumeKg { get; set; }
    public int EstimatedCalories { get; set; }
    public string ComparisonSummary { get; set; } = "";
    public List<string> Highlights { get; set; } = new();
    public List<string> Improvements { get; set; } = new();
    public List<string> MuscleRecoverySummary { get; set; } = new();
    public int ProteinGrams { get; set; }
    public double WaterLiters { get; set; }
    public int CurrentStreak { get; set; }
    public string? NextPlannedSession { get; set; }
}

/// <summary>Phần tường thuật do AI viết - toàn bộ số liệu ở trên là input, không phải output.</summary>
public class WorkoutEvaluationNarrativeDto
{
    public string NarrativeSummary { get; set; } = "";
    public string MealSuggestion { get; set; } = "";
    public string SuggestedNextWorkout { get; set; } = "";
    public string MotivationalMessage { get; set; } = "";
}
