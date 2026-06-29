using GymSupport.Repository.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UserStatsController : ControllerBase
{
    private readonly IWorkoutSessionLogRepository _sessionLogRepository;

    public UserStatsController(IWorkoutSessionLogRepository sessionLogRepository)
    {
        _sessionLogRepository = sessionLogRepository;
    }

    private string? GetCurrentUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

    // ── Exercise stats: last performance + personal records ──────────────────
    // GET /api/users/{userId}/exercise-stats/{exerciseId}
    [HttpGet("{userId}/exercise-stats/{exerciseId}")]
    public async Task<IActionResult> GetExerciseStats(string userId, string exerciseId)
    {
        var currentUserId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(currentUserId)) return Unauthorized();
        if (currentUserId != userId) return Forbid();

        var history = await _sessionLogRepository.GetByUserIdAsync(userId);

        var sessionsWithExercise = history
            .Where(s => s.Status == "COMPLETED")
            .Select(s => new
            {
                date     = (s.EndTime ?? s.StartTime).ToLocalTime(),
                exercise = s.Exercises.FirstOrDefault(e => e.ExerciseId == exerciseId)
            })
            .Where(x => x.exercise != null)
            .OrderByDescending(x => x.date)
            .ToList();

        object? lastPerformance = null;
        if (sessionsWithExercise.Any())
        {
            var last = sessionsWithExercise.First();
            lastPerformance = new
            {
                date         = last.date.ToString("yyyy-MM-dd"),
                exerciseName = last.exercise!.ExerciseName,
                sets = last.exercise.Sets
                    .OrderBy(s => s.SetNumber)
                    .Select(s => new
                    {
                        setNumber = s.SetNumber,
                        weight    = s.Weight ?? 0,
                        reps      = s.Reps ?? 0
                    })
                    .ToList()
            };
        }

        // Personal Records
        var allSets = sessionsWithExercise
            .SelectMany(s => s.exercise!.Sets.Select(set => new
            {
                weight      = set.Weight ?? 0.0,
                reps        = set.Reps ?? 0,
                sessionDate = s.date
            }))
            .ToList();

        object? personalRecord = null;
        if (allSets.Any())
        {
            var maxWeight    = allSets.Max(s => s.weight);
            var maxReps      = allSets.Max(s => s.reps);
            var bestVolumeSet = allSets.OrderByDescending(s => s.weight * s.reps).First();

            personalRecord = new
            {
                maxWeight,
                maxReps,
                bestVolume     = bestVolumeSet.weight * bestVolumeSet.reps,
                bestVolumeDate = bestVolumeSet.sessionDate.ToString("yyyy-MM-dd")
            };
        }

        return Ok(new
        {
            lastPerformance,
            personalRecord,
            totalSessions = sessionsWithExercise.Count
        });
    }

    // ── Weekly stats ─────────────────────────────────────────────────────────
    // GET /api/users/{userId}/stats/weekly?weeks=8
    [HttpGet("{userId}/stats/weekly")]
    public async Task<IActionResult> GetWeeklyStats(string userId, [FromQuery] int weeks = 8)
    {
        var currentUserId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(currentUserId)) return Unauthorized();
        if (currentUserId != userId) return Forbid();

        weeks = Math.Clamp(weeks, 1, 52);

        var history   = await _sessionLogRepository.GetByUserIdAsync(userId);
        var completed = history.Where(s => s.Status == "COMPLETED").ToList();

        var today         = DateTime.Now.Date;
        var daysFromMon   = ((int)today.DayOfWeek + 6) % 7;
        var thisMonday    = today.AddDays(-daysFromMon);

        var result = new List<object>();

        for (var w = weeks - 1; w >= 0; w--)
        {
            var weekStart = thisMonday.AddDays(-7 * w);
            var weekEnd   = weekStart.AddDays(6);

            var wSessions = completed
                .Where(s =>
                {
                    var d = (s.EndTime ?? s.StartTime).ToLocalTime().Date;
                    return d >= weekStart && d <= weekEnd;
                })
                .ToList();

            result.Add(new
            {
                weekStart            = weekStart.ToString("yyyy-MM-dd"),
                weekEnd              = weekEnd.ToString("yyyy-MM-dd"),
                label                = weekStart.ToString("dd/MM"),
                sessionCount         = wSessions.Count,
                totalDurationMinutes = wSessions.Sum(s => s.TotalDurationSeconds) / 60,
                totalSets            = wSessions.Sum(s => s.TotalSets),
                totalVolume          = (long)wSessions.Sum(s => s.TotalVolume),
                totalExpGained       = wSessions.Sum(s => s.TotalExpGained),
                avgDurationMinutes   = wSessions.Any()
                    ? (int)(wSessions.Average(s => s.TotalDurationSeconds) / 60)
                    : 0
            });
        }

        return Ok(result);
    }

    // ── Monthly stats ─────────────────────────────────────────────────────────
    // GET /api/users/{userId}/stats/monthly?months=6
    [HttpGet("{userId}/stats/monthly")]
    public async Task<IActionResult> GetMonthlyStats(string userId, [FromQuery] int months = 6)
    {
        var currentUserId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(currentUserId)) return Unauthorized();
        if (currentUserId != userId) return Forbid();

        months = Math.Clamp(months, 1, 24);

        var history   = await _sessionLogRepository.GetByUserIdAsync(userId);
        var completed = history.Where(s => s.Status == "COMPLETED").ToList();

        var now    = DateTime.Now;
        var result = new List<object>();

        for (var m = months - 1; m >= 0; m--)
        {
            var target     = now.AddMonths(-m);
            var monthStart = new DateTime(target.Year, target.Month, 1);
            var monthEnd   = monthStart.AddMonths(1).AddDays(-1);

            var mSessions = completed
                .Where(s =>
                {
                    var d = (s.EndTime ?? s.StartTime).ToLocalTime().Date;
                    return d >= monthStart && d <= monthEnd;
                })
                .ToList();

            result.Add(new
            {
                month                = monthStart.ToString("yyyy-MM"),
                label                = $"T{monthStart.Month}/{monthStart.Year % 100:D2}",
                sessionCount         = mSessions.Count,
                totalDurationMinutes = mSessions.Sum(s => s.TotalDurationSeconds) / 60,
                totalSets            = mSessions.Sum(s => s.TotalSets),
                totalVolume          = (long)mSessions.Sum(s => s.TotalVolume),
                totalExpGained       = mSessions.Sum(s => s.TotalExpGained),
                avgDurationMinutes   = mSessions.Any()
                    ? (int)(mSessions.Average(s => s.TotalDurationSeconds) / 60)
                    : 0
            });
        }

        return Ok(result);
    }
}
