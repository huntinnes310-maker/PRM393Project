using GymSupport.Repository.Models.Entities;
using GymCoach.Api.Config;
using MongoDB.Driver;
using System.Collections.Generic;
using System.Threading.Tasks;
using GymSupport.Repository.Interfaces;

namespace GymSupport.Repository.Repositories
{
    public class SubscriptionPlanRepository : ISubscriptionPlanRepository
    {
        private readonly IMongoCollection<SubscriptionPlan> _plans;

        public SubscriptionPlanRepository(MongoDbContext context)
        {
            _plans = context.GetCollection<SubscriptionPlan>("SubscriptionPlans");
            var activeIndex = Builders<SubscriptionPlan>.IndexKeys.Ascending(p => p.IsActive);
            _plans.Indexes.CreateOne(new CreateIndexModel<SubscriptionPlan>(activeIndex));
        }

        public async Task<SubscriptionPlan?> GetByIdAsync(string id) =>
            await _plans.Find(p => p.Id == id).FirstOrDefaultAsync();

        public async Task<IEnumerable<SubscriptionPlan>> GetAllAsync() =>
            await _plans.Find(_ => true).ToListAsync();

        public async Task<IEnumerable<SubscriptionPlan>> GetActiveAsync() =>
            await _plans.Find(p => p.IsActive).ToListAsync();

        public Task CreateAsync(SubscriptionPlan plan) =>
            _plans.InsertOneAsync(plan);

        public Task UpdateAsync(SubscriptionPlan plan) =>
            _plans.ReplaceOneAsync(p => p.Id == plan.Id, plan);

        public Task DeleteAsync(string id) =>
            _plans.DeleteOneAsync(p => p.Id == id);
    }
}
