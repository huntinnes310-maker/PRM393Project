using System.Collections.Generic;
using System.Threading.Tasks;

namespace GymSupport.Service.Interfaces
{
    public interface IDashboardService
    {
        Task<DashboardSummaryDto> GetSummaryAsync();
        Task<UserGrowthDto> GetUserGrowthAsync(int year);
        Task<RevenueMonthlyDto> GetRevenueMonthlyAsync(int year);
        Task<RevenueByPlanDto> GetRevenueByPlanAsync(int year);
        Task<UsersBySubscriptionDto> GetUsersBySubscriptionAsync();
    }

    public class DashboardSummaryDto
    {
        public int TotalCustomer { get; set; }
        public int NewCustomerThisMonth { get; set; }
        public int ActiveSubscriptions { get; set; }
        public decimal RevenueThisMonth { get; set; }
        public decimal TotalRevenue { get; set; }
        public int CompletedWorkouts { get; set; }
    }

    public class UserGrowthDto
    {
        public int Year { get; set; }
        public List<UserGrowthMonthDto> Data { get; set; } = new();
    }

    public class UserGrowthMonthDto
    {
        public int Month { get; set; }
        public string MonthName { get; set; } = string.Empty;
        public int NewCustomer { get; set; }
        public int TotalCustomer { get; set; }
    }

    public class RevenueMonthlyDto
    {
        public int Year { get; set; }
        public List<RevenueMonthDto> Data { get; set; } = new();
    }

    public class RevenueMonthDto
    {
        public int Month { get; set; }
        public string MonthName { get; set; } = string.Empty;
        public decimal Revenue { get; set; }
        public int TransactionCount { get; set; }
    }

    public class RevenueByPlanDto
    {
        public int Year { get; set; }
        public List<RevenuePlanDto> Data { get; set; } = new();
    }

    public class RevenuePlanDto
    {
        public string PlanName { get; set; } = string.Empty;
        public decimal Revenue { get; set; }
        public int TransactionCount { get; set; }
    }

    public class UsersBySubscriptionDto
    {
        public List<SubscriptionCountDto> Data { get; set; } = new();
    }

    public class SubscriptionCountDto
    {
        public string Subscription { get; set; } = string.Empty;
        public int Count { get; set; }
    }
}
