using GymSupport.Repository.Models.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace GymSupport.Repository.Interfaces
{
    public interface ICustomerRepository
    {
        Task<IEnumerable<Customer>> GetAllAsync();
        Task<Customer?> GetByIdAsync(string id);
        Task<Customer?> GetByUserIdAsync(string userId);
        Task CreateAsync(Customer customer);
        Task UpdateAsync(Customer customer);
        Task DeleteAsync(string id);
    }
}
