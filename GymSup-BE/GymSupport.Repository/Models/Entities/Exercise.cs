using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class Exercise
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; }

    public string Name { get; set; }
    public string Equipment { get; set; }
    public string Difficulty { get; set; }

    public string Description { get; set; } = "";
    public string Instruction { get; set; } = "";
    public string SafetyNotes { get; set; } = "";
    public string CommonMistakes { get; set; } = "";
    public string Tips { get; set; } = "";
    public int DefaultSets { get; set; } = 3;
    public string DefaultReps { get; set; } = "10";
    public int RestTimeSeconds { get; set; } = 60;

    public string ImageUrl { get; set; }
    public string VideoUrl { get; set; }

    public List<MuscleImpact> MuscleImpacts
    { get; set; } = new();
}
