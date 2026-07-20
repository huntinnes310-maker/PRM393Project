using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

/// <summary>
/// Log chi tiết từng lần gọi OpenAI, dùng để audit/đối soát chi phí thực tế.
/// </summary>
public class AiUsageLog
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    public string UserId { get; set; } = string.Empty;

    public string Feature { get; set; } = string.Empty; // Chat, GenerateWorkoutPlan, AnalyzeImage, AnalyzeFormVideo

    public string Model { get; set; } = string.Empty;

    public int PromptTokens { get; set; }

    public int CompletionTokens { get; set; }

    public decimal CostUsd { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
