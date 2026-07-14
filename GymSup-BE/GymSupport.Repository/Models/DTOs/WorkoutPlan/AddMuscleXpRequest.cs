namespace GymSupport.Repository.Models.DTOs.WorkoutPlan
{
    public class AddMuscleXpRequest
    {
        public string UserId { get; set; } = null!;
        public string MuscleId { get; set; } = null!;
        public int ExpAmount { get; set; }
    }
}
