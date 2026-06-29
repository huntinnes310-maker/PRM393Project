using GymSupport.Repository.Models.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace GymSupport.Repository.Interfaces
{
    public interface ISubscriptionPlanRepository
    {
        Task<SubscriptionPlan?> GetByIdAsync(string id);
        Task<IEnumerable<SubscriptionPlan>> GetAllAsync();
        Task<IEnumerable<SubscriptionPlan>> GetActiveAsync();
        Task CreateAsync(SubscriptionPlan plan);
        Task UpdateAsync(SubscriptionPlan plan);
        Task DeleteAsync(string id);
    }
}
