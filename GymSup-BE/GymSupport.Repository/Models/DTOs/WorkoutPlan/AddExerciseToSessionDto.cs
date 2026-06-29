namespace GymSupport.Repository.Models.DTOs.WorkoutPlan;
public class AddExerciseToSessionDto
{
    public string ExerciseId { get; set; }

    public string? ExerciseName { get; set; }

    public int Sets { get; set; }

    public string Reps { get; set; }

    public string Notes { get; set; }
}
