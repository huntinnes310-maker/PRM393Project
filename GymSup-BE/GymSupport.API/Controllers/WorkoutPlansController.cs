using System.Collections.Generic;
using System.Linq;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using GymSupport.Repository.Models.DTOs.WorkoutPlan;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/workoutplans")]
public class WorkoutPlansController : ControllerBase
{
    private readonly IWorkoutPlanRepository _repository;

    public WorkoutPlansController(IWorkoutPlanRepository repository)
    {
        _repository = repository;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var plans = await _repository.GetAllAsync();
        return Ok(plans);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var plan = await _repository.GetByIdAsync(id);

        if (plan == null)
            return NotFound("Workout plan not found");

        return Ok(plan);
    }

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUser(string userId)
    {
        var plans = await _repository.GetByUserIdAsync(userId);
        return Ok(plans);
    }

    [HttpGet("user/{userId}/active")]
    public async Task<IActionResult> GetActiveByUser(string userId)
    {
        var plan = await _repository.GetActiveByUserIdAsync(userId);

        if (plan == null)
            return NotFound("No active workout plan found");

        return Ok(plan);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] WorkoutPlan plan)
    {
        if (string.IsNullOrWhiteSpace(plan.UserId))
            return BadRequest("UserId is required");

        await _repository.DeactivateAllByUserIdAsync(plan.UserId);

        plan.IsActive = true;

        await _repository.CreateAsync(plan);

        return Ok(plan);
    }

    [HttpPost("create-routine")]
    public async Task<IActionResult> CreateRoutine([FromBody] CreateRoutineDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.UserId))
            return BadRequest("UserId is required");

        // Deactivate all previous plans
        await _repository.DeactivateAllByUserIdAsync(dto.UserId);

        // Create new plan with sessions and exercises
        var plan = new WorkoutPlan
        {
            UserId = dto.UserId,
            Name = dto.Name,
            Goal = dto.Goal,
            Description = dto.Description,
            DaysPerWeek = dto.DaysPerWeek,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            Sessions = dto.Sessions.Select(s => new WorkoutSession
            {
                Id = Guid.NewGuid().ToString(),
                DayOfWeek = s.DayOfWeek,
                Focus = s.Focus,
                Exercises = s.Exercises.Select(e => new ExerciseInSession
                {
                    ExerciseId = e.ExerciseId,
                    ExerciseName = e.ExerciseName,
                    Sets = e.Sets,
                    Reps = e.Reps,
                    Notes = e.Notes
                }).ToList()
            }).ToList()
        };

        await _repository.CreateAsync(plan);

        return Ok(plan);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] WorkoutPlan request)
    {
        var plan = await _repository.GetByIdAsync(id);

        if (plan == null)
            return NotFound("Workout plan not found");

        request.Id = id;

        await _repository.UpdateAsync(request);

        return Ok(request);
    }

    [HttpPost("{id}/sessions")]
    public async Task<IActionResult> AddSession(string id, [FromBody] CreateSessionDto dto)
    {
        var plan = await _repository.GetByIdAsync(id);
        if (plan == null)
            return NotFound("Workout plan not found");

        var session = new WorkoutSession
        {
            Id = Guid.NewGuid().ToString(),
            DayOfWeek = dto.DayOfWeek,
            Focus = dto.Focus,
            Exercises = new List<ExerciseInSession>()
        };

        plan.Sessions.Add(session);
        await _repository.UpdateAsync(plan);

        return Ok(session);
    }

    [HttpPut("{id}/sessions/{sessionId}")]
    public async Task<IActionResult> UpdateSession(string id, string sessionId, [FromBody] UpdateSessionDto dto)
    {
        var plan = await _repository.GetByIdAsync(id);
        if (plan == null)
            return NotFound("Workout plan not found");

        var session = plan.Sessions.FirstOrDefault(x => x.Id == sessionId);
        if (session == null)
            return NotFound("Workout session not found");

        session.DayOfWeek = dto.DayOfWeek;
        session.Focus = dto.Focus;

        await _repository.UpdateAsync(plan);
        return Ok(session);
    }

    [HttpDelete("{id}/sessions/{sessionId}")]
    public async Task<IActionResult> DeleteSession(string id, string sessionId)
    {
        var plan = await _repository.GetByIdAsync(id);
        if (plan == null)
            return NotFound("Workout plan not found");

        var session = plan.Sessions.FirstOrDefault(x => x.Id == sessionId);
        if (session == null)
            return NotFound("Workout session not found");

        plan.Sessions.Remove(session);
        await _repository.UpdateAsync(plan);

        return NoContent();
    }

    [HttpPost("{id}/sessions/{sessionId}/exercises")]
    public async Task<IActionResult> AddExerciseToSession(string id, string sessionId, [FromBody] AddExerciseToSessionDto dto)
    {
        var plan = await _repository.GetByIdAsync(id);
        if (plan == null)
            return NotFound("Workout plan not found");

        var session = plan.Sessions.FirstOrDefault(x => x.Id == sessionId);
        if (session == null)
            return NotFound("Workout session not found");

        var exercise = new ExerciseInSession
        {
            ExerciseId = dto.ExerciseId,
            ExerciseName = dto.ExerciseName ?? string.Empty,
            Sets = dto.Sets,
            Reps = dto.Reps,
            Notes = dto.Notes
        };

        session.Exercises.Add(exercise);
        await _repository.UpdateAsync(plan);

        return Ok(exercise);
    }

    [HttpPut("{id}/sessions/{sessionId}/exercises/{exerciseId}")]
    public async Task<IActionResult> UpdateExerciseInSession(string id, string sessionId, string exerciseId, [FromBody] UpdateExerciseInSessionDto dto)
    {
        var plan = await _repository.GetByIdAsync(id);
        if (plan == null)
            return NotFound("Workout plan not found");

        var session = plan.Sessions.FirstOrDefault(x => x.Id == sessionId);
        if (session == null)
            return NotFound("Workout session not found");

        var exercise = session.Exercises.FirstOrDefault(x => x.ExerciseId == exerciseId);
        if (exercise == null)
            return NotFound("Exercise not found in session");

        exercise.Sets = dto.Sets;
        exercise.Reps = dto.Reps;
        exercise.Notes = dto.Notes;

        await _repository.UpdateAsync(plan);
        return Ok(exercise);
    }

    [HttpDelete("{id}/sessions/{sessionId}/exercises/{exerciseId}")]
    public async Task<IActionResult> DeleteExerciseFromSession(string id, string sessionId, string exerciseId)
    {
        var plan = await _repository.GetByIdAsync(id);
        if (plan == null)
            return NotFound("Workout plan not found");

        var session = plan.Sessions.FirstOrDefault(x => x.Id == sessionId);
        if (session == null)
            return NotFound("Workout session not found");

        var exercise = session.Exercises.FirstOrDefault(x => x.ExerciseId == exerciseId);
        if (exercise == null)
            return NotFound("Exercise not found in session");

        session.Exercises.Remove(exercise);
        await _repository.UpdateAsync(plan);

        return NoContent();
    }

    [HttpPut("{id}/activate")]
    public async Task<IActionResult> Activate(string id)
    {
        var plan = await _repository.GetByIdAsync(id);

        if (plan == null)
            return NotFound("Workout plan not found");

        if (string.IsNullOrWhiteSpace(plan.UserId))
            return BadRequest("Workout plan has no user owner");

        await _repository.DeactivateAllByUserIdAsync(plan.UserId);

        plan.IsActive = true;

        await _repository.UpdateAsync(plan);

        return Ok(plan);
    }

    [HttpPut("{id}/deactivate")]
    public async Task<IActionResult> Deactivate(string id)
    {
        var plan = await _repository.GetByIdAsync(id);

        if (plan == null)
            return NotFound("Workout plan not found");

        plan.IsActive = false;

        await _repository.UpdateAsync(plan);

        return Ok(plan);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var plan = await _repository.GetByIdAsync(id);

        if (plan == null)
            return NotFound("Workout plan not found");

        await _repository.DeleteAsync(id);

        return NoContent();
    }
}
