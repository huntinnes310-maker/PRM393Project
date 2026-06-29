using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class ChatMessage
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; }

    public string UserId { get; set; }

    public string Role { get; set; } // user | assistant

    public string Content { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}