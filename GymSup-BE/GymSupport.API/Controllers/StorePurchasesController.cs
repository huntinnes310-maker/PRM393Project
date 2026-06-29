using System.Security.Claims;
using GymSupport.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Authorize]
[Route("api/store-purchases")]
public sealed class StorePurchasesController : ControllerBase
{
    private readonly IStorePurchaseService _storePurchases;

    public StorePurchasesController(IStorePurchaseService storePurchases)
    {
        _storePurchases = storePurchases;
    }

    [HttpPost("verify")]
    public async Task<IActionResult> Verify([FromBody] VerifyStorePurchaseRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ??
            User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);
        if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

        try
        {
            return Ok(await _storePurchases.VerifyAsync(userId, request));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
