using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/subscriptions")]
[Authorize]
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;

    public SubscriptionsController(ISubscriptionService subscriptionService)
    {
        _subscriptionService = subscriptionService;
    }

    /// <summary>
    /// Get all available subscription plans
    /// </summary>
    [HttpGet("plans")]
    [AllowAnonymous]
    public async Task<IActionResult> GetAllPlans()
    {
        try
        {
            var plans = await _subscriptionService.GetAllSubscriptionPlansAsync();
            return Ok(plans);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving subscription plans", error = ex.Message });
        }
    }

    /// <summary>
    /// Get active subscription plans only
    /// </summary>
    [HttpGet("plans/active")]
    [AllowAnonymous]
    public async Task<IActionResult> GetActivePlans()
    {
        try
        {
            var plans = await _subscriptionService.GetActiveSubscriptionPlansAsync();
            return Ok(plans);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving active subscription plans", error = ex.Message });
        }
    }

    /// <summary>
    /// Get a specific subscription plan by ID
    /// </summary>
    [HttpGet("plans/{id}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetPlanById(string id)
    {
        try
        {
            var plan = await _subscriptionService.GetSubscriptionPlanAsync(id);
            if (plan == null)
                return NotFound(new { message = "Subscription plan not found" });

            return Ok(plan);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving subscription plan", error = ex.Message });
        }
    }

    /// <summary>
    /// Create a new subscription plan (Admin only)
    /// </summary>
    [HttpPost("plans")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreatePlan([FromBody] CreateSubscriptionPlanDto dto)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                return BadRequest(new { message = "Plan name is required" });

            if (dto.DurationMonths <= 0)
                return BadRequest(new { message = "Duration must be greater than 0" });

            if (dto.Price < 0)
                return BadRequest(new { message = "Price cannot be negative" });

            await _subscriptionService.CreateSubscriptionPlanAsync(dto);
            return Created("", new { message = "Subscription plan created successfully" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error creating subscription plan", error = ex.Message });
        }
    }

    /// <summary>
    /// Update subscription plan status (activate/deactivate)
    /// </summary>
    [HttpPatch("plans/{id}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdatePlanStatus(string id, [FromBody] UpdatePlanStatusDto dto)
    {
        try
        {
            await _subscriptionService.UpdateSubscriptionPlanAsync(id, dto.IsActive);
            var status = dto.IsActive ? "activated" : "deactivated";
            return Ok(new { message = $"Subscription plan {status} successfully" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error updating subscription plan", error = ex.Message });
        }
    }

    /// <summary>
    /// Update subscription plan details (Full Update)
    /// </summary>
    [HttpPut("plans/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdatePlan(string id, [FromBody] UpdateSubscriptionPlanDto dto)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                return BadRequest(new { message = "Plan name is required" });

            if (dto.DurationMonths <= 0)
                return BadRequest(new { message = "Duration must be greater than 0" });

            if (dto.Price < 0)
                return BadRequest(new { message = "Price cannot be negative" });

            await _subscriptionService.UpdateSubscriptionPlanFullAsync(id, dto);
            return Ok(new { message = "Subscription plan updated successfully" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error updating subscription plan", error = ex.Message });
        }
    }

    /// <summary>
    /// Delete a subscription plan (Admin only)
    /// </summary>
    [HttpDelete("plans/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeletePlan(string id)
    {
        try
        {
            var plan = await _subscriptionService.GetSubscriptionPlanAsync(id);
            if (plan == null)
                return NotFound(new { message = "Subscription plan not found" });

            await _subscriptionService.DeleteSubscriptionPlanAsync(id);
            return Ok(new { message = "Subscription plan deleted successfully" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error deleting subscription plan", error = ex.Message });
        }
    }

    /// <summary>
    /// Get all user subscriptions (Admin only)
    /// </summary>
    [HttpGet("admin/all")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllUserSubscriptions()
    {
        try
        {
            var subs = await _subscriptionService.GetAllUserSubscriptionsAsync();
            return Ok(subs);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving user subscriptions", error = ex.Message });
        }
    }

    /// <summary>
    /// Get current subscription of authenticated user
    /// Response: { "planName", "startDate", "endDate", "daysRemaining", "status" }
    /// </summary>
    [HttpGet("me")]
    public async Task<IActionResult> GetMySubscription()
    {
        try
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized(new { message = "User ID not found in token" });

            var subscription = await _subscriptionService.GetUserCurrentSubscriptionAsync(userId);
            if (subscription == null)
                return Ok(new { message = "No active subscription" });

            return Ok(subscription);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving user subscription", error = ex.Message });
        }
    }

    /// <summary>
    /// Cancel user's current subscription
    /// </summary>
    [HttpPut("me/cancel")]
    public async Task<IActionResult> CancelSubscription()
    {
        try
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized(new { message = "User ID not found in token" });

            await _subscriptionService.CancelUserSubscriptionAsync(userId);
            return Ok(new { message = "Subscription cancelled successfully" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error cancelling subscription", error = ex.Message });
        }
    }
}

/// <summary>
/// Update subscription plan status DTO
/// </summary>
public class UpdatePlanStatusDto
{
    public bool IsActive { get; set; }
}
