namespace GymSupport.Repository.Models.DTOs.AIModel
{
    public class GenerateWorkoutPlanRequestDto
    {
        public string Goal { get; set; } = "";

        public string ExperienceLevel { get; set; } = "";

        public int? DaysPerWeek { get; set; }

        public List<string> TrainingDays { get; set; } = new();

        public string Intensity { get; set; } = "";

        public string TrainingCondition { get; set; } = "";

        public string HealthIssues { get; set; } = "";
    }
}
