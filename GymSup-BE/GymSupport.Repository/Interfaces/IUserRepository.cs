using GymSupport.Repository.Models.Entities;
using System.Threading.Tasks;

namespace GymSupport.Repository.Interfaces
{
    public interface IUserRepository
    {
        Task<User?> GetByEmailAsync(string email);
        Task<User?> GetByIdAsync(string id);
        Task<IEnumerable<User>> GetAllAsync();
        Task CreateAsync(User user);
        Task UpdateAsync(User user);
        Task DeleteAsync(string id);
    }
}
