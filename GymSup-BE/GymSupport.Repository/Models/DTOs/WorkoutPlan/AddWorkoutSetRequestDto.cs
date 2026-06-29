using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.WorkoutPlan
{
    public class AddWorkoutSetRequestDto
    {
        public int SetNumber { get; set; }

        public double? Weight { get; set; }

        public int? Reps { get; set; }

        public int? DurationSeconds { get; set; }

        public int? Rpe { get; set; }
    }
}
