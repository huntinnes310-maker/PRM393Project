using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.AIModel
{
    public class AISuggestionDto
    {
        public string Action { get; set; } = "";

        public string PlanId { get; set; } = "";

        public string SessionId { get; set; } = "";

        public string ExerciseId { get; set; } = "";

        public string PlanName { get; set; } = "";

        public string Goal { get; set; } = "";

        public string PlanDescription { get; set; } = "";

        public int DaysPerWeek { get; set; }

        public string DayOfWeek { get; set; } = "";

        public string Focus { get; set; } = "";

        public int Sets { get; set; }

        public string Reps { get; set; } = "";

        public string Notes { get; set; } = "";

        // Meal suggestions properties
        public string MealType { get; set; } = "";
        public string MealName { get; set; } = "";
        public int Calories { get; set; }
        public int Protein { get; set; }
        public int Carbs { get; set; }
        public int Fat { get; set; }
    }
}
