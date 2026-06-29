using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.AIModel
{
    public class VideoFormAnalyzeResponseDto
    {
       
            public string Mode { get; set; } = "video_form_check";
            public string Title { get; set; } = string.Empty;
            public string Summary { get; set; } = string.Empty;
            public string TargetExercise { get; set; } = "auto_detect";
            public string DetectedExercise { get; set; } = string.Empty;
            public string Confidence { get; set; } = "medium";
            public bool IsFormAcceptable { get; set; }
            public string RiskLevel { get; set; } = "medium";
            public string OverallVerdict { get; set; } = string.Empty;
            public string MovementSummary { get; set; } = string.Empty;
            public List<string> MajorIssues { get; set; } = new();
            public List<string> MinorIssues { get; set; } = new();
            public List<string> CorrectPoints { get; set; } = new();
            public List<string> FrameObservations { get; set; } = new();
            public List<string> CorrectiveCues { get; set; } = new();
            public List<string> SuggestedFixes { get; set; } = new();
            public List<string> Muscles { get; set; } = new();
            public List<string> Warnings { get; set; } = new();
        }
    }

