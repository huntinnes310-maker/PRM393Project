namespace GymSupport.Repository.Models.DTOs.WorkoutPlan;

public class CreateWorkoutPlanDto
{
    public string UserId { get; set; }

    public string Name { get; set; }

    public string Goal { get; set; }

    public int DaysPerWeek { get; set; }
}