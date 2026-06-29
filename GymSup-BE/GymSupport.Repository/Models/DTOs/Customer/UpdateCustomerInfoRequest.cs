namespace GymSupport.Repository.Models.DTOs.Customer
{
    public class UpdateCustomerInfoRequest
    {
        public string? Gender { get; set; }
        public int? Age { get; set; }
        public double? Bmi { get; set; }
        public int? HeightCm { get; set; }
        public int? WeightKg { get; set; }
        public string? Goal { get; set; }
        public string? ExperienceLevel { get; set; }
        public string? InjuryNotes { get; set; }
        public string? Subscription { get; set; }
    }
}
