using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

/// <summary>
/// Tổng chi phí OpenAI thực tế đã dùng trong một tháng (Id = "yyyy-MM").
/// Đây là "cầu dao tổng" bảo vệ ngân sách thật, độc lập với quota riêng của từng user.
/// </summary>
public class AiMonthlyBudget
{
    [BsonId]
    public string Id { get; set; } = string.Empty; // "yyyy-MM"

    public decimal SpentUsd { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
