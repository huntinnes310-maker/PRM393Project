using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.AIModel
{
    public class ImageAnalyzeResponseDto
    {
        public string Mode { get; set; } = "";
        public string Title { get; set; } = "";
        public string Summary { get; set; } = "";

        public List<string> DetectedItems { get; set; } = new();

        public List<string> BodyObservations { get; set; } = new();

        public List<string> Muscles { get; set; } = new();

        public List<string> PriorityMuscles { get; set; } = new();

        public List<string> SuggestedExercises { get; set; } = new();

        public List<string> FormFeedback { get; set; } = new();

        public List<string> TrainingAdvice { get; set; } = new();

        public List<string> Warnings { get; set; } = new();
    }
}
