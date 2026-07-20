using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IAiUsageRepository
{
    Task<AiMonthlyBudget?> GetMonthlyBudgetAsync(string period);

    /// <summary>Atomically adds <paramref name="amountUsd"/> to the period's spend and returns the new total.</summary>
    Task<decimal> IncrementMonthlySpendAsync(string period, decimal amountUsd);

    Task<AiDailyQuota?> GetDailyQuotaAsync(string userId, string date);

    /// <summary>Atomically increments the given counter field ("Chat", "Generate" or "Analyze") and returns the new count.</summary>
    Task<int> IncrementDailyQuotaAsync(string userId, string date, string counterField);

    Task LogUsageAsync(AiUsageLog log);
}
