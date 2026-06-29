using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class UserSubscription
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;
    
    public string UserId { get; set; } = string.Empty;
    public string PlanId { get; set; } = string.Empty;

    public string PlanName { get; set; } = "free";
    public decimal Price { get; set; }

    public string Status { get; set; } = "Active";
    // Active, Expired, Cancelled

    public DateTime StartedAt { get; set; }
    public DateTime? ExpiredAt { get; set; }
}
