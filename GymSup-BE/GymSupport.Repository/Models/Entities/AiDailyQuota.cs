using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

/// <summary>
/// Số lượt dùng AI của một user trong một ngày (Id = "{userId}_{yyyy-MM-dd}").
/// Đây là quota công bằng theo từng người, tách biệt với cầu dao ngân sách tổng.
/// </summary>
public class AiDailyQuota
{
    [BsonId]
    public string Id { get; set; } = string.Empty; // "{userId}_{yyyy-MM-dd}"

    public string UserId { get; set; } = string.Empty;

    public string Date { get; set; } = string.Empty; // "yyyy-MM-dd"

    public int ChatCount { get; set; }

    public int GenerateCount { get; set; }

    public int AnalyzeCount { get; set; }

    public int EvaluateCount { get; set; }
}
