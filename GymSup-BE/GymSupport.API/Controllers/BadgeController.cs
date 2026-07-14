using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/badges")]
[Authorize]
public class BadgeController : ControllerBase
{
    private readonly IUserBadgeRepository _badgeRepository;
    private readonly IWorkoutSessionLogRepository _workoutLogRepository;
    private readonly IUserMuscleProgressRepository _muscleProgressRepository;

    public BadgeController(
        IUserBadgeRepository badgeRepository,
        IWorkoutSessionLogRepository workoutLogRepository,
        IUserMuscleProgressRepository muscleProgressRepository)
    {
        _badgeRepository = badgeRepository;
        _workoutLogRepository = workoutLogRepository;
        _muscleProgressRepository = muscleProgressRepository;
    }

    private string? GetCurrentUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

    // ─── Danh sách toàn bộ huy hiệu có thể mở khóa ────────────────────────────
    private static readonly List<BadgeDefinition> AllBadgeDefinitions = new()
    {
        // Chuỗi tập luyện (Streak)
        new("streak_3",     "streak",  "🔥 Khởi đầu ấn tượng",  "Tập luyện liên tiếp 3 ngày",     3),
        new("streak_7",     "streak",  "💪 Chiến binh tuần",     "Tập luyện liên tiếp 7 ngày",     7),
        new("streak_14",    "streak",  "⚡ Máy tập bền bỉ",      "Tập luyện liên tiếp 14 ngày",    14),
        new("streak_30",    "streak",  "🏆 Huyền thoại 30 ngày", "Tập luyện liên tiếp 30 ngày",   30),

        // Tổng số buổi tập
        new("workout_1",    "workout", "🎯 Bước chân đầu tiên",  "Hoàn thành buổi tập đầu tiên",   1),
        new("workout_5",    "workout", "🌟 Tân thủ quyết tâm",   "Hoàn thành 5 buổi tập",          5),
        new("workout_10",   "workout", "💥 Chiến binh thực thụ", "Hoàn thành 10 buổi tập",         10),
        new("workout_20",   "workout", "🦁 Dũng mãnh bất bại",   "Hoàn thành 20 buổi tập",         20),
        new("workout_50",   "workout", "👑 Vua phòng tập",        "Hoàn thành 50 buổi tập",         50),
        new("workout_100",  "workout", "🎖 Huyền thoại",          "Hoàn thành 100 buổi tập",        100),

        // Tăng trưởng cơ bắp
        new("muscle_1",     "muscle",  "💪 Cơ bắp đang thức",    "Ghi nhận tiến trình cơ bắp lần đầu", 1),
        new("muscle_3",     "muscle",  "🏋 Sculpting Master",     "Ghi nhận tiến trình 3 nhóm cơ",     3),
        new("muscle_6",     "muscle",  "🦾 Cơ thể lý tưởng",      "Ghi nhận tiến trình 6 nhóm cơ",     6),
    };

    /// <summary>GET /api/badges/definitions - Tất cả huy hiệu có thể mở khóa</summary>
    [HttpGet("definitions")]
    public IActionResult GetDefinitions()
    {
        return Ok(AllBadgeDefinitions.Select(d => new
        {
            badgeId       = d.BadgeId,
            badgeType     = d.BadgeType,
            name          = d.Name,
            description   = d.Description,
            requiredCount = d.RequiredCount
        }));
    }

    /// <summary>GET /api/badges/{userId}/full - Tất cả huy hiệu kèm trạng thái đạt/chưa đạt + tiến độ</summary>
    [HttpGet("{userId}/full")]
    public async Task<IActionResult> GetFullBadgeList(string userId)
    {
        var currentUserId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(currentUserId)) return Unauthorized();
        if (currentUserId != userId) return Forbid();

        // Lấy dữ liệu cần thiết
        var history     = await _workoutLogRepository.GetByUserIdAsync(userId);
        var historyList = history?.ToList() ?? new();
        var completed   = historyList.Count(x => x.Status == "COMPLETED");
        var streak      = CalculateStreak(historyList);

        var muscleProgress = await _muscleProgressRepository.GetByUserIdAsync(userId);
        var muscleCount    = muscleProgress?.Count() ?? 0;

        // Kiểm tra & trao badge mới (auto-award)
        var existing    = await _badgeRepository.GetByUserIdAsync(userId);
        var earnedKeys  = existing.Select(b => b.BadgeType + "_" + b.StreakDays).ToHashSet();

        foreach (var def in AllBadgeDefinitions)
        {
            if (earnedKeys.Contains(def.BadgeId)) continue;
            bool isEarned = def.BadgeType switch
            {
                "streak"  => streak >= def.RequiredCount,
                "workout" => completed >= def.RequiredCount,
                "muscle"  => muscleCount >= def.RequiredCount,
                _ => false
            };
            if (!isEarned) continue;

            var newBadge = new UserBadge
            {
                UserId      = userId,
                BadgeType   = def.BadgeType,
                Name        = def.Name,
                Description = def.Description,
                Emoji       = ExtractEmoji(def.Name),
                StreakDays  = def.RequiredCount,
                EarnedAt    = DateTime.UtcNow
            };
            await _badgeRepository.CreateAsync(newBadge);
            earnedKeys.Add(def.BadgeId);
            existing.Add(newBadge);
        }

        // Tạo map để lookup nhanh
        var earnedMap = existing.ToDictionary(
            b => b.BadgeType + "_" + b.StreakDays,
            b => b);

        var result = AllBadgeDefinitions.Select(def =>
        {
            var isEarned = earnedMap.TryGetValue(def.BadgeId, out var earned);
            int currentProgress = def.BadgeType switch
            {
                "streak"  => streak,
                "workout" => completed,
                "muscle"  => muscleCount,
                _ => 0
            };
            return new
            {
                badgeId         = def.BadgeId,
                badgeType       = def.BadgeType,
                name            = def.Name,
                description     = def.Description,
                emoji           = ExtractEmoji(def.Name),
                requiredCount   = def.RequiredCount,
                currentProgress,
                isEarned,
                earnedAt        = isEarned ? (DateTime?)earned!.EarnedAt : null
            };
        }).ToList();

        return Ok(new
        {
            totalEarned     = earnedKeys.Count,
            totalAvailable  = AllBadgeDefinitions.Count,
            currentStreak   = streak,
            totalWorkouts   = completed,
            badges          = result
        });
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────────
    private static string ExtractEmoji(string name)
    {
        var parts = name.Split(' ');
        return parts.Length > 0 ? parts[0] : "🏅";
    }

    private static int CalculateStreak(List<WorkoutSessionLog> history)
    {
        var completedDates = history
            .Where(x => x.Status == "COMPLETED")
            .Select(x => (x.EndTime ?? x.StartTime).ToLocalTime().Date)
            .Distinct()
            .OrderByDescending(d => d)
            .ToList();

        if (!completedDates.Any()) return 0;

        var today = DateTime.Now.Date;
        // Nếu không có session hôm nay hoặc hôm qua → streak = 0
        if (!completedDates.Contains(today) && !completedDates.Contains(today.AddDays(-1)))
            return 0;

        var checkDate = completedDates.Contains(today) ? today : today.AddDays(-1);
        int streak = 0;
        foreach (var date in completedDates)
        {
            if (date == checkDate) { streak++; checkDate = checkDate.AddDays(-1); }
            else break;
        }
        return streak;
    }
}

public record BadgeDefinition(string BadgeId, string BadgeType, string Name, string Description, int RequiredCount);
