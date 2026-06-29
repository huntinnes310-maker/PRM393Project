using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.WorkoutPlan
{
    public class WorkoutSessionLogModel
    {
        public string UserId { get; set; } = "";

        public string WorkoutPlanId { get; set; } = "";

        public string PlanSessionId { get; set; } = "";
    }
}
