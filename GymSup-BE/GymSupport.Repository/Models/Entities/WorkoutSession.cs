namespace GymSupport.Repository.Models.Entities;

public class WorkoutSession
{
    public string Id { get; set; }

    public string DayOfWeek { get; set; }

    public string Focus { get; set; }

    public List<ExerciseInSession> Exercises { get; set; } = [];
}