using GymSupport.Repository.Models.Entities;
using GymCoach.Api.Config;
using MongoDB.Driver;
using GymSupport.Repository.Interfaces;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace GymSupport.Repository.Repositories
{
    public class CustomerRepository : ICustomerRepository
    {
        private readonly IMongoCollection<Customer> _customers;

        public CustomerRepository(MongoDbContext context)
        {
            _customers = context.GetCollection<Customer>("Customers");
        }

        public async Task<IEnumerable<Customer>> GetAllAsync() =>
            await _customers.Find(_ => true).ToListAsync();

        public async Task<Customer?> GetByIdAsync(string id) =>
            await _customers.Find(c => c.Id == id).FirstOrDefaultAsync();

        public async Task<Customer?> GetByUserIdAsync(string userId) =>
            await _customers.Find(c => c.UserId == userId).FirstOrDefaultAsync();

        public Task CreateAsync(Customer customer) =>
            _customers.InsertOneAsync(customer);

        public Task UpdateAsync(Customer customer) =>
            _customers.ReplaceOneAsync(c => c.Id == customer.Id, customer);

        public Task DeleteAsync(string id) =>
            _customers.DeleteOneAsync(c => c.Id == id);
    }
}
