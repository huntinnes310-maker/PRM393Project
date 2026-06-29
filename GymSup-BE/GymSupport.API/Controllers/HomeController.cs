using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.WorkoutPlan;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/home")]
[Authorize]
public class HomeController : ControllerBase
{
    private readonly IWorkoutPlanRepository _workoutPlanRepository;
    private readonly IWorkoutSessionLogRepository _workoutSessionLogRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IExerciseRepository _exerciseRepository;
    private readonly IMuscleRepository _muscleRepository;
    private readonly IUserMuscleProgressRepository _muscleProgressRepository;
    private readonly IUserBadgeRepository _badgeRepository;

    public HomeController(
        IWorkoutPlanRepository workoutPlanRepository,
        IWorkoutSessionLogRepository workoutSessionLogRepository,
        ICustomerRepository customerRepository,
        IExerciseRepository exerciseRepository,
        IMuscleRepository muscleRepository,
        IUserMuscleProgressRepository muscleProgressRepository,
        IUserBadgeRepository badgeRepository)
    {
        _workoutPlanRepository = workoutPlanRepository;
        _workoutSessionLogRepository = workoutSessionLogRepository;
        _customerRepository = customerRepository;
        _exerciseRepository = exerciseRepository;
        _muscleRepository = muscleRepository;
        _muscleProgressRepository = muscleProgressRepository;
        _badgeRepository = badgeRepository;
    }

    [HttpGet("{userId}")]
    public async Task<IActionResult> GetHome(string userId)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(currentUserId))
            return Unauthorized();

        if (currentUserId != userId)
            return Forbid();

        var plans = await _workoutPlanRepository.GetByUserIdAsync(userId);
        var history = await _workoutSessionLogRepository.GetByUserIdAsync(userId);
        var customer = await _customerRepository.GetByUserIdAsync(userId);
        var exercises = (await _exerciseRepository.GetAllAsync()).ToList();
        var muscles = await _muscleRepository.GetAllAsync();

        var todayPlan = BuildTodayPlan(plans, exercises, muscles);
        var nutrition = BuildNutrition(customer);
        var userMuscleProgress = await _muscleProgressRepository.GetByUserIdAsync(userId);
        var muscleProgress = BuildMuscleProgress(userMuscleProgress, muscles);
        var popularExercises = BuildPopularExercises(history, exercises);
        var badges = await _badgeRepository.GetByUserIdAsync(userId);

        return Ok(new
        {
            history,
            plans,
            todayPlan,
            nutrition,
            muscleProgress,
            popularExercises,
            streak = CalculateScheduleAwareStreak(history),
            workoutCount = history.Count(x => x.Status == "COMPLETED"),
            badges,
        });
    }

    [HttpGet("{userId}/popular-exercises")]
    public async Task<IActionResult> GetPopularExercises(string userId, [FromQuery] int limit = 5)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(currentUserId))
            return Unauthorized();

        if (currentUserId != userId)
            return Forbid();

        var history = await _workoutSessionLogRepository.GetByUserIdAsync(userId);
        var exercises = (await _exerciseRepository.GetAllAsync()).ToList();

        return Ok(BuildPopularExercises(history, exercises, Math.Clamp(limit, 1, 20)));
    }

    private static object? BuildTodayPlan(
        List<WorkoutPlan> plans,
        List<Exercise> exercises,
        List<Muscle> muscles)
    {
        var usablePlans = plans
            .Where(x => x.IsActive)
            .OrderByDescending(x => x.CreatedAt)
            .ToList();
        if (!usablePlans.Any())
            usablePlans = plans.OrderByDescending(x => x.CreatedAt).ToList();

        var today = DateTime.Now.DayOfWeek.ToString();
        WorkoutSession? selectedSession = null;

        foreach (var plan in usablePlans)
        {
            selectedSession = plan.Sessions.FirstOrDefault(x =>
                MatchesToday(x.DayOfWeek, today));

            if (selectedSession != null)
                break;
        }

        if (selectedSession == null)
        {
            selectedSession = usablePlans
                .SelectMany(x => x.Sessions)
                .FirstOrDefault(x => string.Equals(x.DayOfWeek, "Today", StringComparison.OrdinalIgnoreCase));
        }

        if (selectedSession == null)
            return null;

        var exerciseMap = exercises.ToDictionary(x => x.Id, x => x);
        var muscleMap = muscles.ToDictionary(x => x.Id, x => x);

        var sessionExercises = selectedSession.Exercises.Select(item =>
        {
            exerciseMap.TryGetValue(item.ExerciseId, out var exercise);

            var muscleName = "Unknown";
            var firstImpact = exercise?.MuscleImpacts.FirstOrDefault();
            if (firstImpact != null && muscleMap.TryGetValue(firstImpact.MuscleId, out var muscle))
                muscleName = string.IsNullOrWhiteSpace(muscle.Name) ? muscle.Category : muscle.Name;

            return new
            {
                id = item.ExerciseId,
                name = string.IsNullOrWhiteSpace(item.ExerciseName)
                    ? exercise?.Name ?? "Exercise"
                    : item.ExerciseName,
                muscle = muscleName,
                imageUrl = exercise?.ImageUrl ?? "",
                sets = item.Sets,
                reps = item.Reps,
                notes = item.Notes
            };
        }).ToList();

        return new
        {
            day = DisplayDay(selectedSession.DayOfWeek),
            focus = selectedSession.Focus,
            exercises = sessionExercises
        };
    }

    private static bool MatchesToday(string? value, string today)
    {
        if (string.IsNullOrWhiteSpace(value))
            return false;

        var normalized = value.Trim();
        if (string.Equals(normalized, "Today", StringComparison.OrdinalIgnoreCase))
            return true;

        return string.Equals(normalized, today, StringComparison.OrdinalIgnoreCase)
            || string.Equals(normalized, EnglishDayToVietnamese(today), StringComparison.OrdinalIgnoreCase)
            || string.Equals(normalized, EnglishDayToVietnameseNoAccent(today), StringComparison.OrdinalIgnoreCase);
    }

    private static string DisplayDay(string? day)
    {
        if (string.IsNullOrWhiteSpace(day))
            return "Today";

        if (string.Equals(day, "Today", StringComparison.OrdinalIgnoreCase))
            return "Today";

        return $"{EnglishDayToVietnamese(day)} - {day}";
    }

    private static string EnglishDayToVietnamese(string day)
    {
        return day.ToLowerInvariant() switch
        {
            "monday" => "Thứ 2",
            "tuesday" => "Thứ 3",
            "wednesday" => "Thứ 4",
            "thursday" => "Thứ 5",
            "friday" => "Thứ 6",
            "saturday" => "Thứ 7",
            "sunday" => "Chủ nhật",
            _ => day
        };
    }

    private static string EnglishDayToVietnameseNoAccent(string day)
    {
        return day.ToLowerInvariant() switch
        {
            "monday" => "Thu 2",
            "tuesday" => "Thu 3",
            "wednesday" => "Thu 4",
            "thursday" => "Thu 5",
            "friday" => "Thu 6",
            "saturday" => "Thu 7",
            "sunday" => "Chu nhat",
            _ => day
        };
    }

    private static object BuildNutrition(Customer? customer)
    {
        if (customer == null)
        {
            return new
            {
                calories = "—",
                protein = "—",
                water = "—"
            };
        }

        var weight = customer.WeightKg;
        var height = customer.HeightCm;
        var age = customer.Age;

        if (weight <= 0 || height <= 0 || age <= 0)
        {
            return new
            {
                calories = "—",
                protein = weight > 0 ? $"{Math.Round(weight * 1.8)}g" : "—",
                water = weight > 0 ? $"{Math.Round(weight * 35 / 1000.0, 1)}L" : "—"
            };
        }

        var gender = customer.Gender?.ToLowerInvariant() ?? "";
        var goal = customer.Goal?.ToLowerInvariant() ?? "";
        var bmr = gender.Contains("nữ") || gender.Contains("female")
            ? 10 * weight + 6.25 * height - 5 * age - 161
            : 10 * weight + 6.25 * height - 5 * age + 5;

        var calories = bmr * 1.45;
        if (goal.Contains("giảm") || goal.Contains("lose"))
            calories -= 300;
        else if (goal.Contains("tăng cơ") || goal.Contains("strength") || goal.Contains("muscle"))
            calories += 250;

        return new
        {
            calories = $"{Math.Round(calories)} kcal",
            protein = $"{Math.Round(weight * 1.8)}g",
            water = $"{Math.Round(weight * 35 / 1000.0, 1)}L"
        };
    }

    private static List<MuscleProgressDto> BuildMuscleProgress(
        List<UserMuscleProgress> progress,
        List<Muscle> muscles)
    {
        const int expPerLevel = 100;
        var progressByMuscle = progress.ToDictionary(x => x.MuscleId, x => x);
        var averageExp = progress.Any() ? progress.Average(x => x.TotalExp) : 0;

        return muscles
            .Select(muscle =>
            {
                progressByMuscle.TryGetValue(muscle.Id, out var item);
                var totalExp = item?.TotalExp ?? 0;
                var level = Math.Max(1, totalExp / expPerLevel + 1);
                var currentLevelExp = totalExp % expPerLevel;

                return new MuscleProgressDto
                {
                    MuscleId = muscle.Id,
                    Name = string.IsNullOrWhiteSpace(muscle.Name)
                        ? muscle.Category
                        : muscle.Name,
                    Category = muscle.Category ?? "",
                    TotalExp = totalExp,
                    Level = level,
                    CurrentLevelExp = currentLevelExp,
                    ExpToNextLevel = expPerLevel,
                    Progress = currentLevelExp / (double)expPerLevel,
                    Tier = ResolveTier(level),
                    IsLagging = totalExp < Math.Max(expPerLevel, averageExp * 0.7)
                };
            })
            .OrderBy(x => x.TotalExp)
            .ThenBy(x => x.Name)
            .ToList();
    }

    private static string ResolveTier(int level)
    {
        return level switch
        {
            >= 12 => "Champion",
            >= 10 => "Diamond",
            >= 8 => "Platinum",
            >= 6 => "Gold",
            >= 4 => "Silver",
            >= 2 => "Bronze",
            _ => "Iron"
        };
    }

    private static List<object> BuildPopularExercises(
        List<WorkoutSessionLog> history,
        List<Exercise> exercises,
        int limit = 5)
    {
        var fromUtc = DateTime.UtcNow.Date.AddDays(-6);
        var exerciseMap = exercises.ToDictionary(x => x.Id, x => x);

        return history
            .Where(log =>
                string.Equals(log.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase) &&
                (log.EndTime ?? log.StartTime) >= fromUtc)
            .SelectMany(log => log.Exercises
                .Where(item =>
                    string.Equals(item.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase) ||
                    item.Sets.Any(set => string.Equals(
                        set.Status,
                        "COMPLETED",
                        StringComparison.OrdinalIgnoreCase)))
                .Select(item => new
                {
                    item.ExerciseId,
                    item.ExerciseName,
                    CompletedSets = item.Sets.Count(set => string.Equals(
                        set.Status,
                        "COMPLETED",
                        StringComparison.OrdinalIgnoreCase)),
                    PerformedAt = log.EndTime ?? log.StartTime
                }))
            .GroupBy(item => item.ExerciseId)
            .Select(group =>
            {
                exerciseMap.TryGetValue(group.Key, out var exercise);
                return new
                {
                    id = group.Key,
                    name = exercise?.Name ?? group.First().ExerciseName ?? "Exercise",
                    imageUrl = exercise?.ImageUrl ?? "",
                    workoutCount = group.Count(),
                    completedSets = group.Sum(item => item.CompletedSets),
                    lastPerformedAt = group.Max(item => item.PerformedAt)
                };
            })
            .OrderByDescending(item => item.workoutCount)
            .ThenByDescending(item => item.completedSets)
            .ThenByDescending(item => item.lastPerformedAt)
            .Take(limit)
            .Cast<object>()
            .ToList();
    }

    // Uses per-session plan snapshots so changing plans never resets old streaks.
    private static int CalculateScheduleAwareStreak(List<WorkoutSessionLog> history)
    {
        var completed = history
            .Where(x => x.Status == "COMPLETED")
            .Select(x => (
                date: (x.EndTime ?? x.StartTime).ToLocalTime().Date,
                schedule: x.ScheduledDaysOfWeek.Count > 0
                    ? ParseScheduleSnapshot(x.ScheduledDaysOfWeek)
                    : null
            ))
            .OrderBy(x => x.date)
            .ToList();

        if (!completed.Any()) return 0;
        if (completed.All(s => s.schedule == null))
            return CalculateCalendarStreak(history);

        var completedDates = completed.Select(s => s.date).ToHashSet();
        var today = DateTime.Now.Date;
        var streak = 0;

        for (var d = 0; d < 365; d++)
        {
            var date = today.AddDays(-d);

            if (completedDates.Contains(date)) { streak++; continue; }

            var schedule = ResolveScheduleForDate(date, completed);
            if (schedule == null || !schedule.Contains(date.DayOfWeek)) continue;

            if (date < today) break;
        }

        return streak;
    }

    private static HashSet<DayOfWeek>? ResolveScheduleForDate(
        DateTime date,
        List<(DateTime date, HashSet<DayOfWeek>? schedule)> sessions)
    {
        var withSnapshot = sessions.Where(s => s.schedule != null).ToList();
        if (!withSnapshot.Any()) return null;

        var before = withSnapshot.LastOrDefault(s => s.date <= date);
        var after  = withSnapshot.FirstOrDefault(s => s.date > date);

        if (before == default && after == default) return null;
        if (before == default) return after.schedule;
        if (after  == default) return before.schedule;

        var dBefore = (date - before.date).TotalDays;
        var dAfter  = (after.date  - date).TotalDays;
        return dAfter <= dBefore ? after.schedule : before.schedule;
    }

    private static HashSet<DayOfWeek>? ParseScheduleSnapshot(List<string> days)
    {
        var result = new HashSet<DayOfWeek>();
        foreach (var s in days)
            if (Enum.TryParse<DayOfWeek>(s, out var d))
                result.Add(d);
        return result.Count > 0 ? result : null;
    }

    private static int CalculateCalendarStreak(List<WorkoutSessionLog> history)
    {
        var completedDays = history
            .Where(x => x.Status == "COMPLETED")
            .Select(x => (x.EndTime ?? x.StartTime).ToLocalTime().Date)
            .ToHashSet();

        var cursor = DateTime.Now.Date;
        if (!completedDays.Contains(cursor)) cursor = cursor.AddDays(-1);

        var streak = 0;
        while (completedDays.Contains(cursor)) { streak++; cursor = cursor.AddDays(-1); }
        return streak;
    }
}
