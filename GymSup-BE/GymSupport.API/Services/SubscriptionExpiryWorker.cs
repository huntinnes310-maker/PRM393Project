using GymSupport.Repository.Interfaces;

namespace GymSupport.API.Services;

/// <summary>
/// Quét định kỳ và chủ động hạ các subscription "Active" đã qua ExpiredAt
/// xuống "Expired", thay vì chỉ chờ lazy-update khi user tự gọi
/// /api/subscriptions/me (SubscriptionService.GetUserCurrentSubscriptionAsync).
/// Không ảnh hưởng việc chặn tính năng Premium (IsPremium đã tự tính expiry
/// real-time) — mục đích chính là giữ field Status trong DB luôn chính xác.
/// </summary>
public sealed class SubscriptionExpiryWorker : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<SubscriptionExpiryWorker> _logger;

    public SubscriptionExpiryWorker(
        IServiceScopeFactory scopeFactory,
        ILogger<SubscriptionExpiryWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        do
        {
            await ExpireOverdueSubscriptionsAsync(stoppingToken);
        } while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    private async Task ExpireOverdueSubscriptionsAsync(CancellationToken stoppingToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var subscriptions = scope.ServiceProvider.GetRequiredService<IUserSubscriptionRepository>();

        try
        {
            var expiredCount = await subscriptions.ExpireOverdueAsync(DateTime.UtcNow);
            if (expiredCount > 0)
            {
                _logger.LogInformation(
                    "Subscription expiry sweep: đã hạ {Count} subscription về Expired.",
                    expiredCount);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Subscription expiry sweep thất bại.");
        }
    }
}
