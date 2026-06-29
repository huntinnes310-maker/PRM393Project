using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.WorkoutPlan;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;

namespace GymSupport.Service.Services;

public class WorkoutSessionLogService : IWorkoutSessionLogService
{
    private const int ExpPerLevel = 100;

    private static readonly (int days, string type, string name, string description, string emoji)[] StreakMilestones =
    {
        (3,   "streak_3",   "On Fire!",         "Tập 3 ngày liên tiếp",   "🔥"),
        (7,   "streak_7",   "Week Warrior",     "Tập 7 ngày liên tiếp",   "⚡"),
        (14,  "streak_14",  "Two-Week Beast",   "Tập 14 ngày liên tiếp",  "💪"),
        (30,  "streak_30",  "Iron Discipline",  "Tập 30 ngày liên tiếp",  "🏆"),
        (60,  "streak_60",  "Unstoppable",      "Tập 60 ngày liên tiếp",  "🚀"),
        (100, "streak_100", "Legendary",        "Tập 100 ngày liên tiếp", "👑"),
    };

    private readonly IWorkoutSessionLogRepository _sessionLogRepository;
    private readonly IWorkoutPlanRepository _workoutPlanRepository;
    private readonly IExerciseRepository _exerciseRepository;
    private readonly IMuscleRepository _muscleRepository;
    private readonly IUserMuscleProgressRepository _muscleProgressRepository;
    private readonly IUserBadgeRepository _badgeRepository;

    public WorkoutSessionLogService(
        IWorkoutSessionLogRepository sessionLogRepository,
        IWorkoutPlanRepository workoutPlanRepository,
        IExerciseRepository exerciseRepository,
        IMuscleRepository muscleRepository,
        IUserMuscleProgressRepository muscleProgressRepository,
        IUserBadgeRepository badgeRepository)
    {
        _sessionLogRepository = sessionLogRepository;
        _workoutPlanRepository = workoutPlanRepository;
        _exerciseRepository = exerciseRepository;
        _muscleRepository = muscleRepository;
        _muscleProgressRepository = muscleProgressRepository;
        _badgeRepository = badgeRepository;
    }

    public async Task<WorkoutSessionLog> StartSessionAsync(
        StartWorkoutSessionRequestDto dto)
    {
        var activeSession =
            await _sessionLogRepository.GetActiveByUserIdAsync(dto.UserId);

        if (activeSession != null)
        {
            throw new Exception("Bạn đang có một buổi tập chưa hoàn thành.");
        }

        var workoutPlan =
            await _workoutPlanRepository.GetByIdAsync(dto.WorkoutPlanId);

        if (workoutPlan == null)
        {
            throw new Exception("Không tìm thấy workout plan.");
        }

        var planSession = workoutPlan.Sessions
            .FirstOrDefault(x => x.Id == dto.PlanSessionId);

        if (planSession == null)
        {
            throw new Exception("Không tìm thấy buổi tập trong workout plan.");
        }

        var catalogExercises = (await _exerciseRepository.GetAllAsync())
            .ToDictionary(x => x.Id, x => x);

        var exerciseLogs = planSession.Exercises
            .Select((exercise, index) =>
            {
                catalogExercises.TryGetValue(exercise.ExerciseId, out var catalog);

                return new WorkoutExerciseLog
                {
                    ExerciseId = exercise.ExerciseId,
                    ExerciseName = exercise.ExerciseName,
                    MuscleIds = catalog?.MuscleImpacts
                        .Where(x => !string.IsNullOrWhiteSpace(x.MuscleId))
                        .Select(x => x.MuscleId)
                        .Distinct()
                        .ToList() ?? new List<string>(),
                    OrderIndex = index + 1,
                    Status = "PENDING",
                    PlannedSets = exercise.Sets,
                    PlannedReps = exercise.Reps ?? "",
                    Sets = new List<WorkoutSetLog>()
                };
            })
            .ToList();

        var sessionLog = new WorkoutSessionLog
        {
            UserId = dto.UserId,
            WorkoutPlanId = dto.WorkoutPlanId,
            PlanSessionId = dto.PlanSessionId,
            Name = string.IsNullOrWhiteSpace(planSession.Focus)
                ? "Workout Session"
                : planSession.Focus,
            Focus = planSession.Focus,
            StartTime = DateTime.UtcNow,
            Status = "IN_PROGRESS",
            Exercises = exerciseLogs,
            TotalDurationSeconds = 0,
            TotalSets = 0,
            TotalVolume = 0,
            TotalExpGained = 0
        };

        return await _sessionLogRepository.CreateAsync(sessionLog);
    }

    public async Task<WorkoutSessionLog?> GetActiveSessionAsync(
        string userId)
    {
        return await _sessionLogRepository.GetActiveByUserIdAsync(userId);
    }

    public async Task<WorkoutSessionLog> AddSetAsync(
        string sessionLogId,
        string exerciseLogId,
        AddWorkoutSetRequestDto dto)
    {
        var session =
            await _sessionLogRepository.GetByIdAsync(sessionLogId);

        if (session == null)
        {
            throw new Exception("Không tìm thấy buổi tập.");
        }

        if (session.Status != "IN_PROGRESS")
        {
            throw new Exception("Chỉ có thể thêm set khi buổi tập đang diễn ra.");
        }

        var exerciseLog = session.Exercises.FirstOrDefault(
            x => x.Id == exerciseLogId || x.ExerciseId == exerciseLogId);

        if (exerciseLog == null)
        {
            throw new Exception("Không tìm thấy bài tập trong buổi tập.");
        }

        var setLog = new WorkoutSetLog
        {
            SetNumber = dto.SetNumber,
            Weight = dto.Weight,
            Reps = dto.Reps,
            DurationSeconds = dto.DurationSeconds,
            Rpe = dto.Rpe,
            Status = "COMPLETED",
            CreatedAt = DateTime.UtcNow
        };

        var existingSet = exerciseLog.Sets.FirstOrDefault(
            x => x.SetNumber == dto.SetNumber);
        if (existingSet == null)
        {
            exerciseLog.Sets.Add(setLog);
        }
        else
        {
            existingSet.Weight = setLog.Weight;
            existingSet.Reps = setLog.Reps;
            existingSet.DurationSeconds = setLog.DurationSeconds;
            existingSet.Rpe = setLog.Rpe;
            existingSet.Status = "COMPLETED";
            existingSet.CreatedAt = setLog.CreatedAt;
        }
        exerciseLog.Status = "IN_PROGRESS";

        session.TotalSets = session.Exercises
            .SelectMany(x => x.Sets)
            .Count(x => x.Status == "COMPLETED");

        session.TotalVolume = session.Exercises
            .SelectMany(x => x.Sets)
            .Where(x => x.Status == "COMPLETED")
            .Sum(x => (x.Weight ?? 0) * (x.Reps ?? 0));

        await _sessionLogRepository.UpdateAsync(session.Id, session);

        return session;
    }

    public async Task<WorkoutSessionLog> FinishSessionAsync(
        string sessionLogId)
    {
        var session =
            await _sessionLogRepository.GetByIdAsync(sessionLogId);

        if (session == null)
        {
            throw new Exception("Không tìm thấy buổi tập.");
        }

        if (session.Status != "IN_PROGRESS" && session.Status != "PAUSED")
        {
            throw new Exception("Buổi tập này không thể kết thúc.");
        }

        session.EndTime = DateTime.UtcNow;
        session.Status = "COMPLETED";

        session.TotalDurationSeconds =
            (int)(session.EndTime.Value - session.StartTime).TotalSeconds;

        session.TotalSets = session.Exercises
            .SelectMany(x => x.Sets)
            .Count(x => x.Status == "COMPLETED");

        session.TotalVolume = session.Exercises
            .SelectMany(x => x.Sets)
            .Where(x => x.Status == "COMPLETED")
            .Sum(x => (x.Weight ?? 0) * (x.Reps ?? 0));

        foreach (var exercise in session.Exercises)
        {
            if (exercise.Sets.Any(x => x.Status == "COMPLETED"))
            {
                exercise.Status = "COMPLETED";
            }
        }

        session.MuscleExpGains = await ApplyMuscleExpAsync(session);
        session.TotalExpGained = session.MuscleExpGains.Sum(x => x.ExpGained);

        // Snapshot the user's current scheduled days so streak survives future plan changes
        var plans = await _workoutPlanRepository.GetByUserIdAsync(session.UserId);
        session.ScheduledDaysOfWeek = GetScheduledDaysOfWeek(plans)
            .Select(d => d.ToString())
            .ToList();

        await _sessionLogRepository.UpdateAsync(session.Id, session);

        return session;
    }

    public async Task<List<WorkoutSessionLog>> GetHistoryAsync(
        string userId)
    {
        return await _sessionLogRepository.GetByUserIdAsync(userId);
    }

    private async Task<List<MuscleExpGain>> ApplyMuscleExpAsync(
        WorkoutSessionLog session)
    {
        var completedExercises = session.Exercises
            .Where(x => x.Sets.Any(set => set.Status == "COMPLETED"))
            .ToList();

        if (!completedExercises.Any())
        {
            return new List<MuscleExpGain>();
        }

        var exercises = (await _exerciseRepository.GetAllAsync())
            .ToDictionary(x => x.Id, x => x);
        var muscles = (await _muscleRepository.GetAllAsync())
            .ToDictionary(x => x.Id, x => x);
        var expByMuscle = new Dictionary<string, int>();

        foreach (var exerciseLog in completedExercises)
        {
            if (!exercises.TryGetValue(exerciseLog.ExerciseId, out var exercise))
            {
                continue;
            }

            var completedSets = exerciseLog.Sets
                .Where(x => x.Status == "COMPLETED")
                .ToList();
            var exerciseExp = completedSets.Sum(CalculateSetExp);
            if (exerciseExp <= 0)
            {
                continue;
            }

            var impacts = exercise.MuscleImpacts
                .Where(x => !string.IsNullOrWhiteSpace(x.MuscleId))
                .ToList();
            if (!impacts.Any())
            {
                continue;
            }

            var totalImpact = impacts.Sum(x => Math.Max(0, x.Percentage));
            if (totalImpact <= 0)
            {
                totalImpact = impacts.Count;
            }

            foreach (var impact in impacts)
            {
                var weight = Math.Max(0, impact.Percentage);
                if (weight <= 0)
                {
                    weight = 1;
                }

                var gained = Math.Max(
                    1,
                    (int)Math.Round(exerciseExp * (weight / (double)totalImpact)));
                expByMuscle[impact.MuscleId] =
                    expByMuscle.GetValueOrDefault(impact.MuscleId) + gained;
            }
        }

        var gains = new List<MuscleExpGain>();
        foreach (var item in expByMuscle)
        {
            if (!muscles.TryGetValue(item.Key, out var muscle))
            {
                continue;
            }

            var existing = await _muscleProgressRepository.GetByUserAndMuscleAsync(
                session.UserId,
                item.Key);
            var oldTotalExp = existing?.TotalExp ?? 0;
            var newTotalExp = oldTotalExp + item.Value;
            var oldLevel = CalculateLevel(oldTotalExp);
            var newLevel = CalculateLevel(newTotalExp);

            var progress = existing ?? new UserMuscleProgress
            {
                UserId = session.UserId,
                MuscleId = item.Key
            };
            progress.MuscleName = string.IsNullOrWhiteSpace(muscle.Name)
                ? muscle.Category
                : muscle.Name;
            progress.MuscleCategory = muscle.Category ?? "";
            progress.TotalExp = newTotalExp;
            progress.Level = newLevel;
            progress.CurrentLevelExp = newTotalExp % ExpPerLevel;
            progress.ExpToNextLevel = ExpPerLevel;

            await _muscleProgressRepository.UpsertAsync(progress);

            gains.Add(new MuscleExpGain
            {
                MuscleId = item.Key,
                MuscleName = progress.MuscleName,
                ExpGained = item.Value,
                OldLevel = oldLevel,
                NewLevel = newLevel,
                IsLevelUp = newLevel > oldLevel
            });
        }

        return gains
            .OrderByDescending(x => x.ExpGained)
            .ToList();
    }

    private static int CalculateSetExp(WorkoutSetLog set)
    {
        var reps = Math.Max(0, set.Reps ?? 0);
        var weight = Math.Max(0, set.Weight ?? 0);
        var duration = Math.Max(0, set.DurationSeconds ?? 0);
        var volumeBonus = (int)Math.Floor(weight * reps / 120.0);
        var durationBonus = duration / 60;

        return Math.Max(8, 10 + reps + volumeBonus + durationBonus);
    }

    private static int CalculateLevel(int totalExp)
    {
        return Math.Max(1, totalExp / ExpPerLevel + 1);
    }

    public async Task<(int currentStreak, UserBadge? newBadge)> CheckAndAwardStreakBadgeAsync(string userId)
    {
        var history = await _sessionLogRepository.GetByUserIdAsync(userId);
        var streak = CalculateScheduleAwareStreak(history);

        UserBadge? newBadge = null;
        foreach (var (days, type, name, description, emoji) in StreakMilestones.OrderByDescending(m => m.days))
        {
            if (streak < days) continue;

            var existing = await _badgeRepository.GetByUserAndTypeAsync(userId, type);
            if (existing != null) break;

            newBadge = await _badgeRepository.CreateAsync(new UserBadge
            {
                UserId = userId,
                BadgeType = type,
                Name = name,
                Description = description,
                Emoji = emoji,
                StreakDays = days,
            });
            break;
        }

        return (streak, newBadge);
    }

    // Streak only breaks when a SCHEDULED day is missed.
    // Schedule is read from per-session snapshots so plan changes don't reset old streaks.
    // Falls back to calendar streak for sessions without snapshots (legacy data).
    internal static int CalculateScheduleAwareStreak(List<WorkoutSessionLog> history)
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

        // No snapshots at all → legacy data, use calendar streak
        if (completed.All(s => s.schedule == null))
            return CalculateCalendarStreak(history);

        var completedDates = completed.Select(s => s.date).ToHashSet();
        var today = DateTime.Now.Date;
        var streak = 0;

        for (var d = 0; d < 365; d++)
        {
            var date = today.AddDays(-d);

            if (completedDates.Contains(date))
            {
                streak++;
                continue;
            }

            // No workout on this date — check if it was a scheduled day using nearest snapshot
            var schedule = ResolveScheduleForDate(date, completed);
            if (schedule == null || !schedule.Contains(date.DayOfWeek))
                continue; // Rest day or no context — skip

            if (date < today)
                break; // Missed a scheduled day in the past
            // date == today, still time to work out — don't break
        }

        return streak;
    }

    // Find the nearest session (before or after) with a schedule snapshot.
    // Prefers the AFTER session on tie (more likely to reflect current plan).
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
        var dAfter  = (after.date - date).TotalDays;
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
        if (!completedDays.Contains(cursor))
            cursor = cursor.AddDays(-1);

        var streak = 0;
        while (completedDays.Contains(cursor))
        {
            streak++;
            cursor = cursor.AddDays(-1);
        }
        return streak;
    }

    private static HashSet<DayOfWeek> GetScheduledDaysOfWeek(List<WorkoutPlan> plans)
    {
        var days = new HashSet<DayOfWeek>();
        var activePlans = plans.Where(p => p.IsActive).ToList();
        if (!activePlans.Any()) activePlans = plans;

        foreach (var plan in activePlans)
            foreach (var session in plan.Sessions)
            {
                var day = ParseDayOfWeek(session.DayOfWeek);
                if (day.HasValue) days.Add(day.Value);
            }

        return days;
    }

    private static DayOfWeek? ParseDayOfWeek(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        return value.Trim().ToLowerInvariant() switch
        {
            "monday"    or "thu 2" or "thứ 2" or "t2" => DayOfWeek.Monday,
            "tuesday"   or "thu 3" or "thứ 3" or "t3" => DayOfWeek.Tuesday,
            "wednesday" or "thu 4" or "thứ 4" or "t4" => DayOfWeek.Wednesday,
            "thursday"  or "thu 5" or "thứ 5" or "t5" => DayOfWeek.Thursday,
            "friday"    or "thu 6" or "thứ 6" or "t6" => DayOfWeek.Friday,
            "saturday"  or "thu 7" or "thứ 7" or "t7" => DayOfWeek.Saturday,
            "sunday"    or "chu nhat" or "chủ nhật" or "cn" => DayOfWeek.Sunday,
            _ => null
        };
    }
}
