using GymSupport.Repository.Interfaces;
using GymSupport.Service.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace GymSupport.Service.Services;

public class DashboardService : IDashboardService
{
    private readonly IUserRepository _userRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IUserSubscriptionRepository _userSubscriptionRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly IWorkoutSessionLogRepository _workoutSessionLogRepository;

    public DashboardService(
        IUserRepository userRepository,
        ICustomerRepository customerRepository,
        IUserSubscriptionRepository userSubscriptionRepository,
        IPaymentRepository paymentRepository,
        IWorkoutSessionLogRepository workoutSessionLogRepository)
    {
        _userRepository = userRepository;
        _customerRepository = customerRepository;
        _userSubscriptionRepository = userSubscriptionRepository;
        _paymentRepository = paymentRepository;
        _workoutSessionLogRepository = workoutSessionLogRepository;
    }

    public async Task<DashboardSummaryDto> GetSummaryAsync()
    {
        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1);
        var monthEnd = monthStart.AddMonths(1);

        // Total customers (all verified users with role "Customer")
        var allUsers = (await _userRepository.GetAllAsync()).ToList();
        var customers = allUsers.Where(u => u.Role == "Customer").ToList();
        var totalCustomer = customers.Count();

        // New customers this month
        var newCustomerThisMonth = customers
            .Count(c => c.VerifiedAt.HasValue && c.VerifiedAt >= monthStart && c.VerifiedAt < monthEnd);

        // Active subscriptions
        var allSubscriptions = (await _userSubscriptionRepository.GetAllAsync()).ToList();
        var activeSubscriptions = allSubscriptions.Count(s => s.Status == "Active");

        // Revenue this month
        var paymentsThisMonth = await _paymentRepository.GetPaymentsByMonthAsync(now.Year, now.Month);
        var revenueThisMonth = paymentsThisMonth.Sum(p => p.Amount);

        // Total revenue (all paid payments)
        var allPaidPayments = (await _paymentRepository.GetPaidPaymentsAsync()).ToList();
        var totalRevenue = allPaidPayments.Sum(p => p.Amount);

        // Completed workouts - count workouts with EndTime (completed) from all customers
        int completedWorkouts = 0;
        foreach (var customer in customers)
        {
            var logs = await _workoutSessionLogRepository.GetByUserIdAsync(customer.Id);
            completedWorkouts += logs.Count(w => w.EndTime.HasValue);
        }

        return new DashboardSummaryDto
        {
            TotalCustomer = totalCustomer,
            NewCustomerThisMonth = newCustomerThisMonth,
            ActiveSubscriptions = activeSubscriptions,
            RevenueThisMonth = revenueThisMonth,
            TotalRevenue = totalRevenue,
            CompletedWorkouts = completedWorkouts
        };
    }

    public async Task<UserGrowthDto> GetUserGrowthAsync(int year)
    {
        var allUsers = (await _userRepository.GetAllAsync()).ToList();
        var customers = allUsers.Where(u => u.Role == "Customer").ToList();

        var monthNames = new[] { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
        var data = new List<UserGrowthMonthDto>();

        int totalCumulative = 0;

        for (int month = 1; month <= 12; month++)
        {
            var monthStart = new DateTime(year, month, 1);
            var monthEnd = monthStart.AddMonths(1);

            // Count new customers in this month based on VerifiedAt
            var newInMonth = customers.Count(c =>
                c.VerifiedAt.HasValue &&
                c.VerifiedAt >= monthStart &&
                c.VerifiedAt < monthEnd);

            totalCumulative += newInMonth;

            data.Add(new UserGrowthMonthDto
            {
                Month = month,
                MonthName = monthNames[month - 1],
                NewCustomer = newInMonth,
                TotalCustomer = totalCumulative
            });
        }

        return new UserGrowthDto
        {
            Year = year,
            Data = data
        };
    }

    public async Task<RevenueMonthlyDto> GetRevenueMonthlyAsync(int year)
    {
        var allPayments = (await _paymentRepository.GetPaidPaymentsAsync()).ToList();

        var monthNames = new[] { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
        var data = new List<RevenueMonthDto>();

        for (int month = 1; month <= 12; month++)
        {
            var monthStart = new DateTime(year, month, 1);
            var monthEnd = monthStart.AddMonths(1);

            var paymentsInMonth = allPayments.Where(p =>
                p.CreatedAt >= monthStart &&
                p.CreatedAt < monthEnd).ToList();

            var revenue = paymentsInMonth.Sum(p => p.Amount);
            var transactionCount = paymentsInMonth.Count;

            data.Add(new RevenueMonthDto
            {
                Month = month,
                MonthName = monthNames[month - 1],
                Revenue = revenue,
                TransactionCount = transactionCount
            });
        }

        return new RevenueMonthlyDto
        {
            Year = year,
            Data = data
        };
    }

    public async Task<RevenueByPlanDto> GetRevenueByPlanAsync(int year)
    {
        var allPayments = (await _paymentRepository.GetPaidPaymentsAsync()).ToList();

        var startOfYear = new DateTime(year, 1, 1);
        var endOfYear = new DateTime(year, 12, 31, 23, 59, 59);

        var paymentsInYear = allPayments.Where(p =>
            p.CreatedAt >= startOfYear &&
            p.CreatedAt <= endOfYear).ToList();

        var groupedByPlan = paymentsInYear
            .GroupBy(p => p.PlanName)
            .Select(g => new RevenuePlanDto
            {
                PlanName = g.Key,
                Revenue = g.Sum(p => p.Amount),
                TransactionCount = g.Count()
            })
            .OrderByDescending(x => x.Revenue)
            .ToList();

        return new RevenueByPlanDto
        {
            Year = year,
            Data = groupedByPlan
        };
    }

    public async Task<UsersBySubscriptionDto> GetUsersBySubscriptionAsync()
    {
        // Get all users with their subscriptions from UserSubscription table
        var allSubscriptions = (await _userSubscriptionRepository.GetAllAsync()).ToList();

        var groupedBySubscription = allSubscriptions
            .GroupBy(s => s.PlanName.ToLower())
            .Select(g => new SubscriptionCountDto
            {
                Subscription = g.Key,
                Count = g.DistinctBy(s => s.UserId).Count()
            })
            .OrderByDescending(x => x.Count)
            .ToList();

        return new UsersBySubscriptionDto
        {
            Data = groupedBySubscription
        };
    }
}
