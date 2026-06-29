using System.Security.Claims;
using GymSupport.Repository.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace GymSupport.API.Services;

public sealed class PremiumOnlyFilter : IAsyncActionFilter
{
    private readonly IUserSubscriptionRepository _subscriptionRepository;

    public PremiumOnlyFilter(IUserSubscriptionRepository subscriptionRepository)
    {
        _subscriptionRepository = subscriptionRepository;
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

        var subscription = await _subscriptionRepository.GetByUserIdAsync(userId);
        var isPremium = subscription != null &&
            subscription.Status.Equals("Active", StringComparison.OrdinalIgnoreCase) &&
            subscription.Price > 0 &&
            (!subscription.ExpiredAt.HasValue || subscription.ExpiredAt > DateTime.UtcNow);

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
