using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.Entities
{
    public class WorkoutSessionLog
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; } = "";

        [BsonRepresentation(BsonType.ObjectId)]
        public string UserId { get; set; } = "";

        [BsonRepresentation(BsonType.ObjectId)]
        public string? WorkoutPlanId { get; set; }

        public string? PlanSessionId { get; set; }

        public string Name { get; set; } = "";

        public string Focus { get; set; } = "";

        public DateTime StartTime { get; set; } = DateTime.UtcNow;

        public DateTime? EndTime { get; set; }

        public string Status { get; set; } = "IN_PROGRESS";

        public int TotalDurationSeconds { get; set; }

        public int TotalSets { get; set; }

        public double TotalVolume { get; set; }

        public int TotalExpGained { get; set; }

        public string? Notes { get; set; }

        public List<WorkoutExerciseLog> Exercises { get; set; } = new();

        public List<MuscleExpGain> MuscleExpGains { get; set; } = new();

        // Snapshot of the user's scheduled days-of-week at the time this session was completed.
        // Used by the schedule-aware streak algorithm to avoid plan-change false resets.
        public List<string> ScheduledDaysOfWeek { get; set; } = new();

        // Cached AI workout evaluation report (Premium feature). Null until generated;
        // cached here so re-opening the summary never re-triggers an OpenAI call.
        public WorkoutEvaluation? Evaluation { get; set; }
    }
}
