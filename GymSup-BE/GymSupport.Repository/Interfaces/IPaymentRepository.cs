using GymSupport.Repository.Models.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace GymSupport.Repository.Interfaces
{
    public interface IPaymentRepository
    {
        Task<Payment?> GetByIdAsync(string id);
        Task<Payment?> GetByOrderIdAsync(string orderId);
        Task<IEnumerable<Payment>> GetByUserIdAsync(string userId);
        Task<IEnumerable<Payment>> GetByCustomerIdAsync(string customerId);
        Task<IEnumerable<Payment>> GetAllAsync();
        Task CreateAsync(Payment payment);
        Task UpdateAsync(Payment payment);
        Task DeleteAsync(string id);
        Task<IEnumerable<Payment>> GetPaidPaymentsAsync();
        Task<IEnumerable<Payment>> GetPaymentsByMonthAsync(int year, int month);
    }
}
