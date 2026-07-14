using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.Collections.Generic;

namespace GymSupport.Repository.Models.Entities;

[BsonIgnoreExtraElements]
public class UserTodoChecklist
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = "";

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = "";

    public string Date { get; set; } = ""; // format "yyyy-MM-dd"

    public List<string> CustomExerciseIds { get; set; } = new();

    public List<string> CompletedExerciseIds { get; set; } = new();

    public List<string> SubmittedExerciseIds { get; set; } = new();

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
