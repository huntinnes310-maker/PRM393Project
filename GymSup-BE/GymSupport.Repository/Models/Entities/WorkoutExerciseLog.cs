using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.Entities
{
    public class WorkoutExerciseLog
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();

        public string ExerciseId { get; set; } = "";

        public string ExerciseName { get; set; } = "";

        public List<string> MuscleIds { get; set; } = new();

        public int OrderIndex { get; set; }

        public string Status { get; set; } = "PENDING";

        public int PlannedSets { get; set; }

        public string PlannedReps { get; set; } = "";

        public List<WorkoutSetLog> Sets { get; set; } = new();
    }
}
