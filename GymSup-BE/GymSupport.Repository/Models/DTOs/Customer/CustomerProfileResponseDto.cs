using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.Customer
{
    public class CustomerProfileResponseDto
    {
        public string Id { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;

        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;

        public string? Gender { get; set; }
        public int Age { get; set; }
        public double Bmi { get; set; }
        public double HeightCm { get; set; }
        public double WeightKg { get; set; }
        public string? Goal { get; set; }
        public string? ExperienceLevel { get; set; }
        public string? InjuryNotes { get; set; }
        public string? Subscription { get; set; }
    }
}
