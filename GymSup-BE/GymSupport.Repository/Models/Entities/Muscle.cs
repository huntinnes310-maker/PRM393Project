using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class Muscle
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; }
    [BsonElement("name")]
    public string Name { get; set; }
    [BsonElement("category")]
    public string Category { get; set; }
}