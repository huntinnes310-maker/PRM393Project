using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class GoalOption
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; }

    public string Code { get; set; } // BuildMuscle
    public string Name { get; set; } // Tăng cơ
    public string Description { get; set; }
}
