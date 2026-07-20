using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace GymSupport.Service.Interfaces
{
    public interface ISubscriptionService
    {
        Task<SubscriptionPlanDto?> GetSubscriptionPlanAsync(string planId);
        Task<IEnumerable<SubscriptionPlanDto>> GetAllSubscriptionPlansAsync();
        Task<IEnumerable<SubscriptionPlanDto>> GetActiveSubscriptionPlansAsync();
        
        Task<UserSubscriptionDto> ActivateVerifiedSubscriptionAsync(
            string userId,
            string planId,
            DateTime expiresAt);
        Task<UserSubscriptionDto?> GetUserCurrentSubscriptionAsync(string userId);
        Task CancelUserSubscriptionAsync(string userId);
        
        Task UpdateSubscriptionPlanAsync(string planId, bool isActive);
        Task UpdateSubscriptionPlanFullAsync(string planId, UpdateSubscriptionPlanDto dto);
        Task CreateSubscriptionPlanAsync(CreateSubscriptionPlanDto dto);
        Task DeleteSubscriptionPlanAsync(string planId);
        Task<IEnumerable<AdminUserSubscriptionDto>> GetAllUserSubscriptionsAsync();
    }

    public class SubscriptionPlanDto
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public int DurationMonths { get; set; }
        public decimal Price { get; set; }
        public bool IsActive { get; set; }
    }

    public class UserSubscriptionDto
    {
        public string PlanName { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public int DaysRemaining { get; set; }
        public string Status { get; set; } = "active";

        /// <summary>
        /// Nguồn chân lý cho client: true khi gói là Premium VÀ còn hiệu lực
        /// (chưa hết hạn). Gói đã hủy nhưng còn hạn vẫn = true tới hết kỳ.
        /// </summary>
        public bool IsPremium { get; set; }
    }

    public class CreateSubscriptionPlanDto
    {
        public string Name { get; set; } = string.Empty;
        public int DurationMonths { get; set; }
        public decimal Price { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class UpdateSubscriptionPlanDto
    {
        public string Name { get; set; } = string.Empty;
        public int DurationMonths { get; set; }
        public decimal Price { get; set; }
        public bool IsActive { get; set; }
    }

    public class AdminUserSubscriptionDto
    {
        public string Id { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string UserEmail { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string PlanName { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public int DaysRemaining { get; set; }
    }
}
