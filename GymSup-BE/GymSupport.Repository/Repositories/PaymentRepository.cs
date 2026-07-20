using GymSupport.Repository.Models.Entities;
using GymCoach.Api.Config;
using MongoDB.Driver;
using System.Collections.Generic;
using System.Threading.Tasks;
using GymSupport.Repository.Interfaces;

namespace GymSupport.Repository.Repositories
{
    public class PaymentRepository : IPaymentRepository
    {
        private readonly IMongoCollection<Payment> _payments;

        public PaymentRepository(MongoDbContext context)
        {
            _payments = context.GetCollection<Payment>("Payments");
            var userIdIndex = Builders<Payment>.IndexKeys.Ascending(p => p.UserId);
            var customerIdIndex = Builders<Payment>.IndexKeys.Ascending(p => p.CustomerId);
            var createdAtIndex = Builders<Payment>.IndexKeys.Ascending(p => p.CreatedAt);
            var orderIdIndex = Builders<Payment>.IndexKeys.Ascending(p => p.OrderId);
            
            _payments.Indexes.CreateOne(new CreateIndexModel<Payment>(userIdIndex));
            _payments.Indexes.CreateOne(new CreateIndexModel<Payment>(customerIdIndex));
            _payments.Indexes.CreateOne(new CreateIndexModel<Payment>(createdAtIndex));
            _payments.Indexes.CreateOne(new CreateIndexModel<Payment>(
                orderIdIndex,
                new CreateIndexOptions { Unique = true, Sparse = true }));
        }

        public async Task<Payment?> GetByIdAsync(string id) =>
            await _payments.Find(p => p.Id == id).FirstOrDefaultAsync();

        public async Task<Payment?> GetByOrderIdAsync(string orderId) =>
            await _payments.Find(p => p.OrderId == orderId).FirstOrDefaultAsync();

        public async Task<IEnumerable<Payment>> GetByUserIdAsync(string userId) =>
            await _payments.Find(p => p.UserId == userId).ToListAsync();

        public async Task<IEnumerable<Payment>> GetByCustomerIdAsync(string customerId) =>
            await _payments.Find(p => p.CustomerId == customerId).ToListAsync();

        public async Task<IEnumerable<Payment>> GetAllAsync() =>
            await _payments.Find(_ => true).ToListAsync();

        public Task CreateAsync(Payment payment) =>
            _payments.InsertOneAsync(payment);

        public Task UpdateAsync(Payment payment) =>
            _payments.ReplaceOneAsync(p => p.Id == payment.Id, payment);

        public Task DeleteAsync(string id) =>
            _payments.DeleteOneAsync(p => p.Id == id);

        public async Task<IEnumerable<Payment>> GetPaidPaymentsAsync() =>
            await _payments.Find(p => p.Status == "Paid").ToListAsync();

        public async Task<IEnumerable<Payment>> GetPaymentsByMonthAsync(int year, int month)
        {
            var startDate = new DateTime(year, month, 1);
            var endDate = startDate.AddMonths(1);

            return await _payments.Find(p =>
                p.Status == "Paid" &&
                p.CreatedAt >= startDate &&
                p.CreatedAt < endDate
            ).ToListAsync();
        }
    }
}
