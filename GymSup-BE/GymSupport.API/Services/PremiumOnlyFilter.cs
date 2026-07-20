using System.Security.Claims;
using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace GymSupport.API.Services;

public sealed class PremiumOnlyFilter : IAsyncActionFilter
{
    private readonly ISubscriptionService _subscriptionService;

    public PremiumOnlyFilter(ISubscriptionService subscriptionService)
    {
        _subscriptionService = subscriptionService;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        var userId = context.HttpContext.User.FindFirstValue(ClaimTypes.NameIdentifier) ??
            context.HttpContext.User.FindFirstValue(
                System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);
        if (string.IsNullOrWhiteSpace(userId))
        {
            context.Result = new UnauthorizedResult();
            return;
        }

        // Cùng một nguồn sự thật với /api/subscriptions/me — tránh 2 định nghĩa
        // "premium" lệch nhau giữa filter này và SubscriptionService.
        var subscription = await _subscriptionService.GetUserCurrentSubscriptionAsync(userId);
        var isPremium = subscription?.IsPremium ?? false;

        if (!isPremium)
        {
            context.Result = new ObjectResult(new
            {
                code = "PREMIUM_REQUIRED",
                message = "Tính năng này yêu cầu gói Premium đang hoạt động."
            })
            {
                StatusCode = StatusCodes.Status403Forbidden
            };
            return;
        }

        await next();
    }
}
