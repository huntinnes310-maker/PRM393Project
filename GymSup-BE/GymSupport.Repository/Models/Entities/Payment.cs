using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class Payment
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    public string UserId { get; set; } = string.Empty;
    public string? CustomerId { get; set; }

    public string PaymentType { get; set; } = "Subscription";
    // Subscription, Other

    public string PlanName { get; set; } = string.Empty;
    public string PlanId { get; set; } = string.Empty;

    public decimal Amount { get; set; }

    public string PaymentMethod { get; set; } = string.Empty;
    // GOOGLE_PLAY, APP_STORE, Other

    public string Status { get; set; } = "Pending";
    // Pending, Paid, Failed, Cancelled, Refunded

    public string OrderId { get; set; } = string.Empty;
    public string RequestId { get; set; } = string.Empty;
    public string? TransactionId { get; set; }
    public int? ProviderResultCode { get; set; }
    public string? ProviderMessage { get; set; }

    public DateTime? PaidAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
}
