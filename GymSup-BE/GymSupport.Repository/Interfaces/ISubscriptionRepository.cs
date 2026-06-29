using GymSupport.Repository.Models.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace GymSupport.Repository.Interfaces
{
    public interface IUserSubscriptionRepository
    {
        Task<UserSubscription?> GetByIdAsync(string id);
        Task<UserSubscription?> GetByUserIdAsync(string userId);
        Task<IEnumerable<UserSubscription>> GetAllAsync();
        Task CreateAsync(UserSubscription subscription);
        Task UpdateAsync(UserSubscription subscription);
        Task DeleteAsync(string id);
    }
}
