using GymSupport.Repository.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/users/{userId}/badges")]
[Authorize]
public class BadgesController : ControllerBase
{
    private readonly IUserBadgeRepository _badgeRepository;

    public BadgesController(IUserBadgeRepository badgeRepository)
    {
        _badgeRepository = badgeRepository;
    }

    [HttpGet]
    public async Task<IActionResult> GetBadges(string userId)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(currentUserId))
            return Unauthorized();

        if (currentUserId != userId)
            return Forbid();

        var badges = await _badgeRepository.GetByUserIdAsync(userId);
        return Ok(badges);
    }
}
