namespace GymSupport.Repository.Models.DTOs.WorkoutPlan;

public class MuscleProgressDto
{
    public string MuscleId { get; set; } = "";

    public string Name { get; set; } = "";

    public string Category { get; set; } = "";

    public int TotalExp { get; set; }

    public int Level { get; set; } = 1;

    public int CurrentLevelExp { get; set; }

    public int ExpToNextLevel { get; set; } = 100;

    public double Progress { get; set; }

    public string Tier { get; set; } = "Iron";

    public bool IsLagging { get; set; }
}
