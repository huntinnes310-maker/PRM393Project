using GymCoach.Api.Config;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MongoDB.Bson;
using MongoDB.Driver;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/todo-checklist")]
[Authorize]
public class TodoChecklistController : ControllerBase
{
    private readonly IMongoCollection<UserTodoChecklist> _collection;

    public TodoChecklistController(MongoDbContext context)
    {
        _collection = context.GetCollection<UserTodoChecklist>("UserTodoChecklist");
    }

    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] string userId, [FromQuery] string date)
    {
        if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(date))
            return BadRequest("UserId và Date là bắt buộc.");

        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(currentUserId))
            return Unauthorized();

        if (currentUserId != userId)
            return Forbid();

        var checklist = await _collection
            .Find(x => x.UserId == userId && x.Date == date)
            .FirstOrDefaultAsync();

        if (checklist == null)
        {
            return Ok(new
            {
                userId = userId,
                date = date,
                customExerciseIds = new List<string>(),
                completedExerciseIds = new List<string>(),
                submittedExerciseIds = new List<string>()
            });
        }

        return Ok(new
        {
            userId = checklist.UserId,
            date = checklist.Date,
            customExerciseIds = checklist.CustomExerciseIds ?? new List<string>(),
            completedExerciseIds = checklist.CompletedExerciseIds ?? new List<string>(),
            submittedExerciseIds = checklist.SubmittedExerciseIds ?? new List<string>()
        });
    }

    [HttpPost]
    public async Task<IActionResult> Save([FromBody] SaveTodoChecklistRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.UserId) || string.IsNullOrWhiteSpace(request.Date))
            return BadRequest("Dữ liệu yêu cầu không hợp lệ.");

        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(currentUserId))
            return Unauthorized();

        if (currentUserId != request.UserId)
            return Forbid();

        var existing = await _collection
            .Find(x => x.UserId == request.UserId && x.Date == request.Date)
            .FirstOrDefaultAsync();

        var checklist = existing ?? new UserTodoChecklist
        {
            UserId = request.UserId,
            Date = request.Date
        };

        if (string.IsNullOrEmpty(checklist.Id))
        {
            checklist.Id = ObjectId.GenerateNewId().ToString();
        }

        checklist.CustomExerciseIds = request.CustomExerciseIds ?? new List<string>();
        checklist.CompletedExerciseIds = request.CompletedExerciseIds ?? new List<string>();
        checklist.SubmittedExerciseIds = request.SubmittedExerciseIds ?? new List<string>();
        checklist.UpdatedAt = DateTime.UtcNow;

        await _collection.ReplaceOneAsync(
            x => x.UserId == checklist.UserId && x.Date == checklist.Date,
            checklist,
            new ReplaceOptions { IsUpsert = true });

        return Ok(new { success = true });
    }
}

public class SaveTodoChecklistRequest
{
    public string UserId { get; set; } = "";
    public string Date { get; set; } = "";
    public List<string> CustomExerciseIds { get; set; } = new();
    public List<string> CompletedExerciseIds { get; set; } = new();
    public List<string> SubmittedExerciseIds { get; set; } = new();
}
