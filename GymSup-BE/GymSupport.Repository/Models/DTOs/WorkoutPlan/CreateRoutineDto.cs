namespace GymSupport.Repository.Models.DTOs.WorkoutPlan;

public class CreateRoutineDto
{
    public string UserId { get; set; }
    public string Name { get; set; }
    public string Goal { get; set; }
    public string Description { get; set; } = "";
    public int DaysPerWeek { get; set; }
    public List<RoutineSessionDto> Sessions { get; set; } = [];
}

public class RoutineSessionDto
{
    public string DayOfWeek { get; set; }
    public string Focus { get; set; }
    public List<RoutineExerciseDto> Exercises { get; set; } = [];
}

public class RoutineExerciseDto
{
    public string ExerciseId { get; set; }
    public string ExerciseName { get; set; }
    public int Sets { get; set; }
    public string Reps { get; set; }
    public string Notes { get; set; } = string.Empty;
}
