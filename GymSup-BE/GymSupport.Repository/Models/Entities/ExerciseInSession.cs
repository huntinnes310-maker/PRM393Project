namespace GymSupport.Repository.Models.Entities;

public class ExerciseInSession
{
    public string ExerciseId { get; set; }
    public string ExerciseName { get; set; } = string.Empty;
    public int Sets { get; set; }

    public string Reps { get; set; }

    public string Notes { get; set; }
}
