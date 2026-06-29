using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

[BsonIgnoreExtraElements]
public class Customer
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    
    public string Id { get; set; }

    public string UserId { get; set; }

    public string? Gender { get; set; }
    public int Age { get; set; }
    public double Bmi { get; set; }

    public int HeightCm { get; set; }
    public int WeightKg { get; set; }

    public string? Goal { get; set; }
    public string? ExperienceLevel { get; set; }
    public string? InjuryNotes { get; set; }
}
