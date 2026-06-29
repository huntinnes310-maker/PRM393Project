using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.WorkoutPlan;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/muscle-progress")]
[Authorize]
public class MuscleProgressController : ControllerBase
{
    private const int ExpPerLevel = 100;

    private readonly IUserMuscleProgressRepository _progressRepository;
    private readonly IMuscleRepository _muscleRepository;

    public MuscleProgressController(
        IUserMuscleProgressRepository progressRepository,
        IMuscleRepository muscleRepository)
    {
        _progressRepository = progressRepository;
        _muscleRepository = muscleRepository;
    }

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUser(string userId)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(currentUserId))
            return Unauthorized();

        if (currentUserId != userId)
            return Forbid();

        var muscles = await _muscleRepository.GetAllAsync();
        var progress = await _progressRepository.GetByUserIdAsync(userId);
        var progressByMuscle = progress.ToDictionary(x => x.MuscleId, x => x);
        var averageExp = progress.Any() ? progress.Average(x => x.TotalExp) : 0;

        var result = muscles
            .Select(muscle =>
            {
                progressByMuscle.TryGetValue(muscle.Id, out var item);
                var totalExp = item?.TotalExp ?? 0;
                var level = Math.Max(1, totalExp / ExpPerLevel + 1);
                var currentLevelExp = totalExp % ExpPerLevel;

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
                    ExpToNextLevel = ExpPerLevel,
                    Progress = currentLevelExp / (double)ExpPerLevel,
                    Tier = ResolveTier(level),
                    IsLagging = totalExp < Math.Max(ExpPerLevel, averageExp * 0.7)
                };
            })
            .OrderBy(x => x.TotalExp)
            .ThenBy(x => x.Name)
            .ToList();

        return Ok(result);
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
}
