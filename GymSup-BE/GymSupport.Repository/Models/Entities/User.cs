using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    public string FullName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;

    public string Role { get; set; } = null!; // Admin, Manager, Customer
    public bool IsActive { get; set; } = true;
    // public string? GymId { get; set; }

    public DateTime CreatedAt { get; set; }
    public bool IsEmailVerified { get; set; }
    public DateTime? VerifiedAt { get; set; }
    public string? EmailVerificationToken { get; set; }
    public DateTime? EmailVerificationTokenExpiresAt { get; set; }
}
