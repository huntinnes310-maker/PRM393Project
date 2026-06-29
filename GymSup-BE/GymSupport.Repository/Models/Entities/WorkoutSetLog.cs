using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.Entities
{
    public class WorkoutSetLog
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();

        public int SetNumber { get; set; }

        public double? Weight { get; set; }

        public int? Reps { get; set; }

        public int? DurationSeconds { get; set; }

        public int? Rpe { get; set; }

        public string Status { get; set; } = "COMPLETED";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
