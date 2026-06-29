using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.Exercise
{
    public class CreateExerciseDto
    {
        public string Name { get; set; }

        public string Equipment { get; set; }

        public string Difficulty { get; set; }

        public string Description { get; set; } = "";

        public string Instruction { get; set; } = "";

        public string SafetyNotes { get; set; } = "";

        public string CommonMistakes { get; set; } = "";

        public string Tips { get; set; } = "";

        public int DefaultSets { get; set; } = 3;

        public string DefaultReps { get; set; } = "10";

        public int RestTimeSeconds { get; set; } = 60;

        public string ImageUrl { get; set; }

        public string VideoUrl { get; set; }

        public List<MuscleImpactDto> MuscleImpacts
        { get; set; } = new();
    }
}
