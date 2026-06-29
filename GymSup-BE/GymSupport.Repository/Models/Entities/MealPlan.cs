using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace GymSupport.Repository.Models.Entities;

public class MealPlan
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; }

    public string UserId { get; set; }
    public DateTime Date { get; set; }

    public int TotalCalories { get; set; }
    public int Protein { get; set; }
    public int Carbs { get; set; }
    public int Fat { get; set; }

    public List<MealItem> Meals { get; set; }
}
