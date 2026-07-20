using System.Security.Claims;
using GymSupport.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/payments/payos")]
public sealed class PaymentsController : ControllerBase
{
    private readonly IPayOsService _payOs;

    public PaymentsController(IPayOsService payOs)
    {
        _payOs = payOs;
    }

    [Authorize]
    [HttpPost("checkout")]
    public async Task<IActionResult> CreateCheckout([FromBody] CreatePayOsCheckoutRequest request)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();
        if (string.IsNullOrWhiteSpace(request.PlanId))
            return BadRequest(new { message = "Thiếu planId." });

        try
        {
            return Ok(await _payOs.CreateCheckoutAsync(userId, request.PlanId));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpGet("status/{orderCode}")]
    public async Task<IActionResult> GetStatus(string orderCode)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId)) return Unauthorized();

        try
        {
            return Ok(await _payOs.GetStatusAsync(userId, orderCode));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [AllowAnonymous]
    [HttpPost("webhook")]
    public async Task<IActionResult> Webhook([FromBody] PayOsWebhookRequest payload)
    {
        try
        {
            await _payOs.HandleWebhookAsync(payload);
        }
        catch (InvalidOperationException)
        {
            // Chữ ký không hợp lệ hoặc payload sai — không lộ chi tiết ra ngoài.
            return BadRequest();
        }
        // Luôn trả 200 khi xử lý xong (kể cả no-op) để PayOS ngưng gửi lại webhook.
        return Ok();
    }

    private string? GetUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);
}

public sealed class CreatePayOsCheckoutRequest
{
    public string PlanId { get; set; } = string.Empty;
}
