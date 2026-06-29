using GymSupport.Repository.Interfaces;
using GymSupport.Service.Interfaces;

namespace GymSupport.Service.Services;

public class AnalyticsService : IAnalyticsService
{
    private readonly IUserRepository _userRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IWorkoutSessionLogRepository _workoutSessionLogRepository;
    private readonly IWorkoutPlanRepository _workoutPlanRepository;
    private readonly IChatRepository _chatRepository;
    private readonly IUserSubscriptionRepository _userSubscriptionRepository;
    private readonly IMealPlanRepository _mealPlanRepository;

    public AnalyticsService(
        IUserRepository userRepository,
        ICustomerRepository customerRepository,
        IWorkoutSessionLogRepository workoutSessionLogRepository,
        IWorkoutPlanRepository workoutPlanRepository,
        IChatRepository chatRepository,
        IUserSubscriptionRepository userSubscriptionRepository,
        IMealPlanRepository mealPlanRepository)
    {
        _userRepository = userRepository;
        _customerRepository = customerRepository;
        _workoutSessionLogRepository = workoutSessionLogRepository;
        _workoutPlanRepository = workoutPlanRepository;
        _chatRepository = chatRepository;
        _userSubscriptionRepository = userSubscriptionRepository;
        _mealPlanRepository = mealPlanRepository;
    }

    // ── API 2: Active Users ───────────────────────────────────────────────────

    public async Task<ActiveUsersDto> GetActiveUsersAsync(DateTime from, DateTime to)
    {
        // Activity is measured by WorkoutSessionLog.StartTime (no app-open event exists yet)
        var fromDate = from.Date;
        var toExclusive = to.Date.AddDays(1);

        var sessions = await _workoutSessionLogRepository.GetByDateRangeAsync(fromDate, toExclusive);

        // Daily breakdown: unique users per calendar day
        var dailyBreakdown = new List<DailyActiveDto>();
        for (var day = fromDate; day < toExclusive; day = day.AddDays(1))
        {
            var nextDay = day.AddDays(1);
            var uniqueUsers = sessions
                .Where(s => s.StartTime >= day && s.StartTime < nextDay)
                .Select(s => s.UserId)
                .Distinct()
                .Count();

            dailyBreakdown.Add(new DailyActiveDto
            {
                Date = day.ToString("yyyy-MM-dd"),
                ActiveUsers = uniqueUsers
            });
        }

        // DAU = average of daily unique user counts
        var dau = dailyBreakdown.Count > 0 ? dailyBreakdown.Average(d => d.ActiveUsers) : 0;

        // WAU = average of weekly unique user counts
        var weeklyUniques = new List<int>();
        for (var weekStart = fromDate; weekStart < toExclusive; weekStart = weekStart.AddDays(7))
        {
            var weekEnd = weekStart.AddDays(7);
            if (weekEnd > toExclusive) weekEnd = toExclusive;
            var count = sessions
                .Where(s => s.StartTime >= weekStart && s.StartTime < weekEnd)
                .Select(s => s.UserId)
                .Distinct()
                .Count();
            weeklyUniques.Add(count);
        }
        var wau = weeklyUniques.Count > 0 ? weeklyUniques.Average() : 0;

        // MAU = unique users across the whole period
        var mau = sessions.Select(s => s.UserId).Distinct().Count();

        return new ActiveUsersDto
        {
            From = from.ToString("yyyy-MM-dd"),
            To = to.ToString("yyyy-MM-dd"),
            Dau = Math.Round(dau, 1),
            Wau = Math.Round(wau, 1),
            Mau = mau,
            DailyBreakdown = dailyBreakdown
        };
    }

    // ── API 3: Retention ─────────────────────────────────────────────────────

    public async Task<RetentionDto> GetRetentionAsync(DateTime from, DateTime to)
    {
        var fromDate = from.Date;
        var toExclusive = to.Date.AddDays(1);
        var today = DateTime.UtcNow.Date;

        // Cohort = customers who verified their email in [from, to]
        var allUsers = (await _userRepository.GetAllAsync()).ToList();
        var cohort = allUsers
            .Where(u =>
                u.Role == "Customer" &&
                u.VerifiedAt.HasValue &&
                u.VerifiedAt.Value.Date >= fromDate &&
                u.VerifiedAt.Value.Date < toExclusive)
            .ToList();

        if (cohort.Count == 0)
        {
            return new RetentionDto
            {
                From = from.ToString("yyyy-MM-dd"),
                To = to.ToString("yyyy-MM-dd"),
                CohortSize = 0
            };
        }

        int day1Retained = 0, day7Retained = 0, day30Retained = 0;
        int day7Eligible = 0, day30Eligible = 0;

        foreach (var user in cohort)
        {
            var regDate = user.VerifiedAt!.Value.Date;
            var sessions = await _workoutSessionLogRepository.GetByUserIdAsync(user.Id);

            // Day 1: any workout session on day 1 after registration (24h–48h window)
            var d1Start = regDate.AddDays(1);
            var d1End = regDate.AddDays(2);
            if (sessions.Any(s => s.StartTime.Date >= d1Start && s.StartTime.Date < d1End))
                day1Retained++;

            // Day 7: session in the day-6 to day-9 window (only if 7 days have passed)
            if (regDate.AddDays(6) <= today)
            {
                day7Eligible++;
                var d7Start = regDate.AddDays(6);
                var d7End = regDate.AddDays(9);
                if (sessions.Any(s => s.StartTime.Date >= d7Start && s.StartTime.Date < d7End))
                    day7Retained++;
            }

            // Day 30: session in the day-28 to day-33 window (only if 30 days have passed)
            if (regDate.AddDays(28) <= today)
            {
                day30Eligible++;
                var d30Start = regDate.AddDays(28);
                var d30End = regDate.AddDays(33);
                if (sessions.Any(s => s.StartTime.Date >= d30Start && s.StartTime.Date < d30End))
                    day30Retained++;
            }
        }

        var cohortSize = cohort.Count;

        return new RetentionDto
        {
            From = from.ToString("yyyy-MM-dd"),
            To = to.ToString("yyyy-MM-dd"),
            CohortSize = cohortSize,
            Day1Retention = cohortSize > 0 ? Math.Round((double)day1Retained / cohortSize * 100, 1) : 0,
            Day7Retention = day7Eligible > 0 ? Math.Round((double)day7Retained / day7Eligible * 100, 1) : 0,
            Day30Retention = day30Eligible > 0 ? Math.Round((double)day30Retained / day30Eligible * 100, 1) : 0,
            Day1RetainedUsers = day1Retained,
            Day7RetainedUsers = day7Retained,
            Day30RetainedUsers = day30Retained,
            Day7EligibleUsers = day7Eligible,
            Day30EligibleUsers = day30Eligible
        };
    }

    // ── API 4: Funnel ─────────────────────────────────────────────────────────

    public async Task<FunnelDto> GetFunnelAsync(string name)
    {
        if (name != "onboarding_to_workout")
            return new FunnelDto { Name = name, Steps = new() };

        // Fetch all data needed
        var allUsers = (await _userRepository.GetAllAsync()).ToList();
        var customers = allUsers
            .Where(u => u.Role == "Customer" && u.VerifiedAt.HasValue)
            .ToList();
        var customerIds = customers.Select(u => u.Id).ToHashSet();

        var allProfiles = (await _customerRepository.GetAllAsync()).ToList();
        var profileUserIds = allProfiles.Select(c => c.UserId).ToHashSet();

        var allPlans = (await _workoutPlanRepository.GetAllAsync()).ToList();
        var usersWithPlan = allPlans.Select(p => p.UserId).ToHashSet();

        var allSessions = await _workoutSessionLogRepository.GetAllAsync();
        var usersWithSession = allSessions.Select(s => s.UserId).ToHashSet();
        var usersWithCompletedSession = allSessions
            .Where(s => s.EndTime.HasValue)
            .Select(s => s.UserId)
            .ToHashSet();

        // Count users at each funnel step
        int step1 = customers.Count;
        int step2 = customerIds.Count(id => profileUserIds.Contains(id));
        int step3 = customerIds.Count(id => usersWithPlan.Contains(id));
        int step4 = customerIds.Count(id => usersWithSession.Contains(id));
        int step5 = customerIds.Count(id => usersWithCompletedSession.Contains(id));

        var counts = new[]
        {
            ("register_success",      "Đăng ký thành công",       step1),
            ("onboarding_completed",  "Hoàn thành onboarding",     step2),
            ("workout_plan_created",  "Tạo kế hoạch tập luyện",   step3),
            ("workout_started",       "Bắt đầu buổi tập",          step4),
            ("workout_completed",     "Hoàn thành buổi tập",       step5)
        };

        var steps = new List<FunnelStepDto>();
        int prev = 0;

        for (int i = 0; i < counts.Length; i++)
        {
            var (key, label, count) = counts[i];

            double fromPrev = i == 0
                ? 100.0
                : (prev > 0 ? Math.Round((double)count / prev * 100, 1) : 0);

            double fromStart = step1 > 0
                ? Math.Round((double)count / step1 * 100, 1)
                : 0;

            steps.Add(new FunnelStepDto
            {
                Step = key,
                Label = label,
                Count = count,
                ConversionFromPrevious = fromPrev,
                ConversionFromStart = fromStart,
                DroppedFromPrevious = i == 0 ? 0 : prev - count
            });

            prev = count;
        }

        return new FunnelDto { Name = name, Steps = steps };
    }

    // ── API 5: Feature Usage ─────────────────────────────────────────────────

    public async Task<FeatureUsageDto> GetFeatureUsageAsync(DateTime from, DateTime to)
    {
        var fromDate = from.Date;
        var toExclusive = to.Date.AddDays(1);

        // Workout sessions
        var sessions = await _workoutSessionLogRepository.GetByDateRangeAsync(fromDate, toExclusive);
        int workoutCount = sessions.Count;
        int workoutUsers = sessions.Select(s => s.UserId).Distinct().Count();

        // AI Coach (count user-sent messages only to avoid counting assistant replies)
        var chatMessages = await _chatRepository.GetByDateRangeAsync(fromDate, toExclusive);
        var userMessages = chatMessages.Where(m => m.Role == "user").ToList();
        int aiCoachCount = userMessages.Count;
        int aiCoachUsers = userMessages.Select(m => m.UserId).Distinct().Count();

        // Generate Plan (workout plans created)
        var allPlans = (await _workoutPlanRepository.GetAllAsync()).ToList();
        var plansInRange = allPlans
            .Where(p => p.CreatedAt >= fromDate && p.CreatedAt < toExclusive)
            .ToList();
        int generatePlanCount = plansInRange.Count;
        int generatePlanUsers = plansInRange.Select(p => p.UserId).Distinct().Count();

        // Nutrition (meal plans logged)
        var mealPlans = await _mealPlanRepository.GetByDateRangeAsync(fromDate, toExclusive);
        int nutritionCount = mealPlans.Count;
        int nutritionUsers = mealPlans.Select(m => m.UserId).Distinct().Count();

        // Subscription (new subscriptions started)
        var allSubs = (await _userSubscriptionRepository.GetAllAsync()).ToList();
        var subsInRange = allSubs
            .Where(s => s.StartedAt >= fromDate && s.StartedAt < toExclusive)
            .ToList();
        int subscriptionCount = subsInRange.Count;
        int subscriptionUsers = subsInRange.Select(s => s.UserId).Distinct().Count();

        return new FeatureUsageDto
        {
            From = from.ToString("yyyy-MM-dd"),
            To = to.ToString("yyyy-MM-dd"),
            Features = new List<FeatureUsageItemDto>
            {
                new() { Feature = "Workout",        UsageCount = workoutCount,       UniqueUsers = workoutUsers },
                new() { Feature = "AI Coach",       UsageCount = aiCoachCount,       UniqueUsers = aiCoachUsers },
                new() { Feature = "Scan Equipment", UsageCount = 0,                  UniqueUsers = 0 },
                new() { Feature = "Generate Plan",  UsageCount = generatePlanCount,  UniqueUsers = generatePlanUsers },
                new() { Feature = "Nutrition",      UsageCount = nutritionCount,     UniqueUsers = nutritionUsers },
                new() { Feature = "Subscription",   UsageCount = subscriptionCount,  UniqueUsers = subscriptionUsers },
                new() { Feature = "Profile",        UsageCount = 0,                  UniqueUsers = 0 }
            }
        };
    }

    // ── API 6: Workout Behavior ───────────────────────────────────────────────

    public async Task<WorkoutAnalyticsDto> GetWorkoutAnalyticsAsync(DateTime from, DateTime to)
    {
        var fromDate = from.Date;
        var toExclusive = to.Date.AddDays(1);

        var sessions = await _workoutSessionLogRepository.GetByDateRangeAsync(fromDate, toExclusive);

        int totalStarted = sessions.Count;
        var completed = sessions.Where(s => s.EndTime.HasValue).ToList();
        int totalCompleted = completed.Count;

        double completionRate = totalStarted > 0
            ? Math.Round((double)totalCompleted / totalStarted * 100, 1)
            : 0;

        double avgDurationMinutes = completed.Count > 0
            ? Math.Round(completed.Average(s => s.TotalDurationSeconds) / 60.0, 1)
            : 0;

        // Top 10 most used exercises
        var topExercises = sessions
            .SelectMany(s => s.Exercises)
            .GroupBy(e => e.ExerciseName)
            .Select(g => new ExerciseUsageDto { ExerciseName = g.Key, Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .Take(10)
            .ToList();

        // Top 10 most trained muscle groups (ranked by total EXP gained)
        var topMuscles = sessions
            .SelectMany(s => s.MuscleExpGains)
            .GroupBy(m => m.MuscleName)
            .Select(g => new MuscleUsageDto
            {
                MuscleName = g.Key,
                TotalExpGained = g.Sum(m => m.ExpGained),
                AppearanceCount = g.Count()
            })
            .OrderByDescending(x => x.TotalExpGained)
            .Take(10)
            .ToList();

        // Top 10 most consistent users (by session count)
        var allUsers = (await _userRepository.GetAllAsync()).ToList();
        var userNameMap = allUsers.ToDictionary(u => u.Id, u => u.FullName);

        var topUsers = sessions
            .GroupBy(s => s.UserId)
            .Select(g => new ConsistentUserDto
            {
                UserId = g.Key,
                UserName = userNameMap.TryGetValue(g.Key, out var name) ? name : "Unknown",
                SessionCount = g.Count(),
                CompletedSessions = g.Count(s => s.EndTime.HasValue)
            })
            .OrderByDescending(x => x.SessionCount)
            .Take(10)
            .ToList();

        return new WorkoutAnalyticsDto
        {
            From = from.ToString("yyyy-MM-dd"),
            To = to.ToString("yyyy-MM-dd"),
            TotalSessionsStarted = totalStarted,
            TotalSessionsCompleted = totalCompleted,
            CompletionRate = completionRate,
            AverageDurationMinutes = avgDurationMinutes,
            MostPopularExercises = topExercises,
            MostTrainedMuscles = topMuscles,
            MostConsistentUsers = topUsers
        };
    }
}
