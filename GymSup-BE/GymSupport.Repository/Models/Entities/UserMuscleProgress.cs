using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class UserMuscleProgress
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = "";

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = "";

    [BsonRepresentation(BsonType.ObjectId)]
    public string MuscleId { get; set; } = "";

    public string MuscleName { get; set; } = "";

    public string MuscleCategory { get; set; } = "";

    public int TotalExp { get; set; }

    public int Level { get; set; } = 1;

    public int CurrentLevelExp { get; set; }

    public int ExpToNextLevel { get; set; } = 100;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
