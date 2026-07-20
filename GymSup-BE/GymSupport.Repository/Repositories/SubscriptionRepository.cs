using GymSupport.Repository.Models.Entities;
using GymCoach.Api.Config;
using MongoDB.Driver;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using GymSupport.Repository.Interfaces;

namespace GymSupport.Repository.Repositories
{
    public class UserSubscriptionRepository : IUserSubscriptionRepository
    {
        private readonly IMongoCollection<UserSubscription> _subscriptions;

        public UserSubscriptionRepository(MongoDbContext context)
        {
            _subscriptions = context.GetCollection<UserSubscription>("UserSubscriptions");
            var userIdIndex = Builders<UserSubscription>.IndexKeys.Ascending(s => s.UserId);
            _subscriptions.Indexes.CreateOne(new CreateIndexModel<UserSubscription>(userIdIndex));
        }

        public async Task<UserSubscription?> GetByIdAsync(string id) =>
            await _subscriptions.Find(s => s.Id == id).FirstOrDefaultAsync();

        public async Task<UserSubscription?> GetByUserIdAsync(string userId) =>
            await _subscriptions.Find(s => s.UserId == userId).FirstOrDefaultAsync();

        public async Task<IEnumerable<UserSubscription>> GetAllAsync() =>
            await _subscriptions.Find(_ => true).ToListAsync();

        public Task CreateAsync(UserSubscription subscription) =>
            _subscriptions.InsertOneAsync(subscription);

        public Task UpdateAsync(UserSubscription subscription) =>
            _subscriptions.ReplaceOneAsync(s => s.Id == subscription.Id, subscription);

        public Task DeleteAsync(string id) =>
            _subscriptions.DeleteOneAsync(s => s.Id == id);

        public async Task<long> ExpireOverdueAsync(DateTime asOf)
        {
            var filter = Builders<UserSubscription>.Filter.And(
                Builders<UserSubscription>.Filter.Eq(s => s.Status, "Active"),
                Builders<UserSubscription>.Filter.Ne(s => s.ExpiredAt, null),
                Builders<UserSubscription>.Filter.Lte(s => s.ExpiredAt, asOf));
            var update = Builders<UserSubscription>.Update.Set(s => s.Status, "Expired");
            var result = await _subscriptions.UpdateManyAsync(filter, update);
            return result.ModifiedCount;
        }
    }
}
