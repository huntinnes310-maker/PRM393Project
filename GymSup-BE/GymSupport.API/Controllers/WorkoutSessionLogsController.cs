using GymSupport.Repository.Models.DTOs.WorkoutPlan;

using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/workout-session-logs")]
public class WorkoutSessionLogsController : ControllerBase
{
    private readonly IWorkoutSessionLogService _service;

    public WorkoutSessionLogsController(
        IWorkoutSessionLogService service)
    {
        _service = service;
    }

    [HttpPost("start")]
    public async Task<IActionResult> StartSession(
        StartWorkoutSessionRequestDto dto)
    {
        try
        {
            var result = await _service.StartSessionAsync(dto);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpGet("active/{userId}")]
    public async Task<IActionResult> GetActiveSession(
        string userId)
    {
        var result = await _service.GetActiveSessionAsync(userId);

        if (result == null)
        {
            return NotFound(new
            {
                message = "Không có buổi tập nào đang diễn ra."
            });
        }

        return Ok(result);
    }

    [HttpPost("{sessionLogId}/exercises/{exerciseLogId}/sets")]
    public async Task<IActionResult> AddSet(
        string sessionLogId,
        string exerciseLogId,
        AddWorkoutSetRequestDto dto)
    {
        try
        {
            var result = await _service.AddSetAsync(
                sessionLogId,
                exerciseLogId,
                dto);

            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpPut("{sessionLogId}/finish")]
    public async Task<IActionResult> FinishSession(
        string sessionLogId)
    {
        try
        {
            var session = await _service.FinishSessionAsync(sessionLogId);
            var (streak, newBadge) = await _service.CheckAndAwardStreakBadgeAsync(session.UserId);

            return Ok(new
            {
                session,
                currentStreak = streak,
                newBadge,
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpGet("user/{userId}/history")]
    public async Task<IActionResult> GetHistory(
        string userId)
    {
        var result = await _service.GetHistoryAsync(userId);
        return Ok(result);
    }
}
