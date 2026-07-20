using GymSupport.Repository.Models.Entities;
using System;
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

        /// <summary>
        /// Chuyển hàng loạt các subscription đang "Active" nhưng đã qua ExpiredAt
        /// sang "Expired". Trả về số bản ghi bị đổi.
        /// </summary>
        Task<long> ExpireOverdueAsync(DateTime asOf);
    }
}
