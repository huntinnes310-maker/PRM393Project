using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/admin/dashboard")]
[Authorize(Roles = "Admin,Manager")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    /// <summary>
    /// Get dashboard summary with key metrics (cards at top of dashboard)
    /// </summary>
    /// <remarks>
    /// Returns summary data for:
    /// - Total customers
    /// - New customers this month
    /// - Active subscriptions
    /// - Revenue this month
    /// - Total revenue
    /// - Completed workouts
    /// </remarks>
    /// <returns>Dashboard summary object</returns>
    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary()
    {
        try
        {
            var summary = await _dashboardService.GetSummaryAsync();
            return Ok(summary);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving dashboard summary", error = ex.Message });
        }
    }

    /// <summary>
    /// Get user growth data by month for a specific year
    /// </summary>
    /// <remarks>
    /// Used to draw a line/area chart showing user growth over the year.
    /// New users are counted based on their VerifiedAt date.
    /// </remarks>
    /// <param name="year">The year to get user growth for</param>
    /// <returns>User growth data with monthly breakdown</returns>
    [HttpGet("user-growth")]
    public async Task<IActionResult> GetUserGrowth([FromQuery] int year)
    {
        try
        {
            if (year < 2000 || year > DateTime.UtcNow.Year + 10)
                return BadRequest(new { message = "Invalid year" });

            var growth = await _dashboardService.GetUserGrowthAsync(year);
            return Ok(growth);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving user growth data", error = ex.Message });
        }
    }

    /// <summary>
    /// Get monthly revenue data for a specific year
    /// </summary>
    /// <remarks>
    /// Used to draw a bar/line chart showing revenue distribution by month.
    /// Only counts payments with Status = "Paid".
    /// </remarks>
    /// <param name="year">The year to get revenue for</param>
    /// <returns>Monthly revenue data</returns>
    [HttpGet("revenue/monthly")]
    public async Task<IActionResult> GetRevenueMonthly([FromQuery] int year)
    {
        try
        {
            if (year < 2000 || year > DateTime.UtcNow.Year + 10)
                return BadRequest(new { message = "Invalid year" });

            var revenue = await _dashboardService.GetRevenueMonthlyAsync(year);
            return Ok(revenue);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving monthly revenue data", error = ex.Message });
        }
    }

    /// <summary>
    /// Get revenue breakdown by subscription plan for a specific year
    /// </summary>
    /// <remarks>
    /// Used to draw a pie/donut or bar chart showing revenue distribution across plans.
    /// Only counts payments with Status = "Paid".
    /// </remarks>
    /// <param name="year">The year to get revenue breakdown for</param>
    /// <returns>Revenue by plan data</returns>
    [HttpGet("revenue/by-plan")]
    public async Task<IActionResult> GetRevenueByPlan([FromQuery] int year)
    {
        try
        {
            if (year < 2000 || year > DateTime.UtcNow.Year + 10)
                return BadRequest(new { message = "Invalid year" });

            var revenue = await _dashboardService.GetRevenueByPlanAsync(year);
            return Ok(revenue);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving revenue by plan data", error = ex.Message });
        }
    }

    /// <summary>
    /// Get distribution of users by current subscription type
    /// </summary>
    /// <remarks>
    /// Used to draw a pie/donut chart showing how many users are on each subscription plan.
    /// Data is taken from Customer.Subscription field (free, premium, pro, etc).
    /// </remarks>
    /// <returns>User count by subscription type</returns>
    [HttpGet("users/by-subscription")]
    public async Task<IActionResult> GetUsersBySubscription()
    {
        try
        {
            var users = await _dashboardService.GetUsersBySubscriptionAsync();
            return Ok(users);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error retrieving users by subscription data", error = ex.Message });
        }
    }
}
