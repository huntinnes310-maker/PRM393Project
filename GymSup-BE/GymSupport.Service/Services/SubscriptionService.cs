using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Concurrent;

namespace GymSupport.Service.Services;

public class SubscriptionService : ISubscriptionService
{
    private readonly ISubscriptionPlanRepository _planRepository;
    private readonly IUserSubscriptionRepository _userSubscriptionRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IUserRepository _userRepository;

    public SubscriptionService(
        ISubscriptionPlanRepository planRepository,
        IUserSubscriptionRepository userSubscriptionRepository,
        ICustomerRepository customerRepository,
        IUserRepository userRepository)
    {
        _planRepository = planRepository;
        _userSubscriptionRepository = userSubscriptionRepository;
        _customerRepository = customerRepository;
        _userRepository = userRepository;
    }

    public async Task<SubscriptionPlanDto?> GetSubscriptionPlanAsync(string planId)
    {
        var plan = await _planRepository.GetByIdAsync(planId);
        if (plan == null)
            return null;

        return MapToPlanDto(plan);
    }

    public async Task<IEnumerable<SubscriptionPlanDto>> GetAllSubscriptionPlansAsync()
    {
        var plans = await _planRepository.GetAllAsync();
        return plans.Select(MapToPlanDto).ToList();
    }

    public async Task<IEnumerable<SubscriptionPlanDto>> GetActiveSubscriptionPlansAsync()
    {
        var plans = await _planRepository.GetActiveAsync();
        return plans.Select(MapToPlanDto).ToList();
    }

    public async Task<UserSubscriptionDto> ActivateVerifiedSubscriptionAsync(
        string userId,
        string planId,
        DateTime expiresAt)
    {
        var plan = await _planRepository.GetByIdAsync(planId)
            ?? throw new InvalidOperationException("Gói đăng ký không tồn tại.");
        if (!plan.IsActive)
            throw new InvalidOperationException("Gói đăng ký hiện không hoạt động.");

        var now = DateTime.UtcNow;
        var normalizedExpiry = expiresAt.Kind == DateTimeKind.Utc
            ? expiresAt
            : expiresAt.ToUniversalTime();
        if (normalizedExpiry <= now)
            throw new InvalidOperationException("Giao dịch Store đã hết hạn.");

        var subscription = await _userSubscriptionRepository.GetByUserIdAsync(userId);
        if (subscription == null)
        {
            subscription = new UserSubscription
            {
                UserId = userId,
                PlanId = plan.Id,
                PlanName = plan.Name,
                Price = plan.Price,
                Status = "Active",
                StartedAt = now,
                ExpiredAt = normalizedExpiry
            };
            await _userSubscriptionRepository.CreateAsync(subscription);
        }
        else
        {
            subscription.PlanId = plan.Id;
            subscription.PlanName = plan.Name;
            subscription.Price = plan.Price;
            subscription.Status = "Active";
            subscription.StartedAt = now;
            subscription.ExpiredAt = normalizedExpiry;
            await _userSubscriptionRepository.UpdateAsync(subscription);
        }

        return new UserSubscriptionDto
        {
            PlanName = subscription.PlanName,
            StartDate = subscription.StartedAt,
            EndDate = normalizedExpiry,
            DaysRemaining = Math.Max(0, (int)(normalizedExpiry - now).TotalDays),
            Status = "active",
            IsPremium = true
        };
    }

    public async Task<UserSubscriptionDto?> GetUserCurrentSubscriptionAsync(string userId)
    {
        var subscription = await _userSubscriptionRepository.GetByUserIdAsync(userId);
        if (subscription == null)
            return null;

        var now = DateTime.UtcNow;
        var daysRemaining = 0;

        if (subscription.ExpiredAt.HasValue)
        {
            daysRemaining = (int)(subscription.ExpiredAt.Value - now).TotalDays;
            if (subscription.ExpiredAt.Value <= now &&
                subscription.Status.Equals("Active", StringComparison.OrdinalIgnoreCase))
            {
                subscription.Status = "Expired";
                await _userSubscriptionRepository.UpdateAsync(subscription);
            }
        }

        // Còn hiệu lực = gói trả phí (Price > 0) VÀ chưa qua ngày hết hạn. Trạng thái
        // "Cancelled" (hủy gia hạn) vẫn giữ quyền tới hết kỳ nên chỉ dựa vào mốc thời
        // gian, không dựa vào tên gói — plan có thể được đặt tên bất kỳ (vd "hội viên
        // năm"/"hội viên tháng"), không nhất thiết phải chứa chữ "premium".
        var isPremium = subscription.Price > 0
            && !subscription.Status.Equals("Expired", StringComparison.OrdinalIgnoreCase)
            && subscription.ExpiredAt.HasValue
            && subscription.ExpiredAt.Value > now;

        return new UserSubscriptionDto
        {
            PlanName = subscription.PlanName,
            StartDate = subscription.StartedAt,
            EndDate = subscription.ExpiredAt ?? now,
            DaysRemaining = Math.Max(0, daysRemaining),
            Status = subscription.Status.ToLower(),
            IsPremium = isPremium
        };
    }

    public async Task CancelUserSubscriptionAsync(string userId)
    {
        var subscription = await _userSubscriptionRepository.GetByUserIdAsync(userId);
        if (subscription == null)
            throw new Exception("Người dùng không có gói đăng ký nào.");

        subscription.Status = "Cancelled";
        await _userSubscriptionRepository.UpdateAsync(subscription);

    }

    public async Task UpdateSubscriptionPlanAsync(string planId, bool isActive)
    {
        var plan = await _planRepository.GetByIdAsync(planId);
        if (plan == null)
            throw new Exception("Gói đăng ký không tồn tại.");

        plan.IsActive = isActive;
        plan.UpdatedAt = DateTime.UtcNow;
        
        await _planRepository.UpdateAsync(plan);
    }

    public async Task CreateSubscriptionPlanAsync(CreateSubscriptionPlanDto dto)
    {
        var plan = new SubscriptionPlan
        {
            Name = dto.Name,
            DurationMonths = dto.DurationMonths,
            Price = dto.Price,
            IsActive = dto.IsActive,
            CreatedAt = DateTime.UtcNow
        };

        await _planRepository.CreateAsync(plan);
    }

    public async Task UpdateSubscriptionPlanFullAsync(string planId, UpdateSubscriptionPlanDto dto)
    {
        var plan = await _planRepository.GetByIdAsync(planId);
        if (plan == null)
            throw new Exception("Gói đăng ký không tồn tại.");

        plan.Name = dto.Name;
        plan.DurationMonths = dto.DurationMonths;
        plan.Price = dto.Price;
        plan.IsActive = dto.IsActive;
        plan.UpdatedAt = DateTime.UtcNow;
        
        await _planRepository.UpdateAsync(plan);
    }

    public async Task DeleteSubscriptionPlanAsync(string planId)
    {
        await _planRepository.DeleteAsync(planId);
    }

    public async Task<IEnumerable<AdminUserSubscriptionDto>> GetAllUserSubscriptionsAsync()
    {
        var subscriptions = await _userSubscriptionRepository.GetAllAsync();
        var now = DateTime.UtcNow;
        var result = new List<AdminUserSubscriptionDto>();

        foreach (var sub in subscriptions)
        {
            var user = await _userRepository.GetByIdAsync(sub.UserId);
            var daysRemaining = sub.ExpiredAt.HasValue
                ? Math.Max(0, (int)(sub.ExpiredAt.Value - now).TotalDays)
                : 0;

            result.Add(new AdminUserSubscriptionDto
            {
                Id = sub.Id,
                UserId = sub.UserId,
                UserEmail = user?.Email ?? "",
                UserName = user?.FullName ?? "",
                PlanName = sub.PlanName,
                Price = sub.Price,
                Status = sub.Status,
                StartDate = sub.StartedAt,
                EndDate = sub.ExpiredAt,
                DaysRemaining = daysRemaining,
            });
        }

        return result.OrderByDescending(s => s.StartDate);
    }

    private SubscriptionPlanDto MapToPlanDto(SubscriptionPlan plan)
    {
        return new SubscriptionPlanDto
        {
            Id = plan.Id,
            Name = plan.Name,
            DurationMonths = plan.DurationMonths,
            Price = plan.Price,
            IsActive = plan.IsActive
        };
    }
}
