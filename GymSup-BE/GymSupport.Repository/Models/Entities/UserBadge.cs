using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class UserBadge
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = "";

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = "";

    public string BadgeType { get; set; } = "";

    public string Name { get; set; } = "";

    public string Description { get; set; } = "";

    public string Emoji { get; set; } = "";

    public int StreakDays { get; set; }

    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
}
