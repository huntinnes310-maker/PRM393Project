using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Repositories
{
    public class WorkoutPlanRepository : IWorkoutPlanRepository
    {
        private readonly IMongoCollection<WorkoutPlan> _collection;

        public WorkoutPlanRepository(MongoDbContext context)
        {
            _collection = context.GetCollection<WorkoutPlan>("WorkoutPlans");
        }

        public async Task<List<WorkoutPlan>> GetAllAsync()
        {
            return await _collection.Find(_ => true).ToListAsync();
        }

        public async Task<WorkoutPlan?> GetByIdAsync(string id)
        {
            if (string.IsNullOrEmpty(id) || id.Length != 24 || !System.Text.RegularExpressions.Regex.IsMatch(id, @"^[0-9a-fA-F]{24}$"))
            {
                // Trả về null luôn chứ không để lỗi MongoDB format làm sập API
                return null;
            }
            return await _collection
                .Find(x => x.Id == id)
                .FirstOrDefaultAsync();
        }

        public async Task<List<WorkoutPlan>> GetByUserIdAsync(string userId)
        {
            return await _collection
                .Find(x => x.UserId == userId)
                .ToListAsync();
        }

        public async Task CreateAsync(WorkoutPlan plan)
        {
            await _collection.InsertOneAsync(plan);
        }

        public async Task DeleteAsync(string id)
        {
            await _collection.DeleteOneAsync(x => x.Id == id);
        }

        public async Task UpdateAsync(WorkoutPlan plan)
        {
            await _collection.ReplaceOneAsync(
                x => x.Id == plan.Id,
                plan);
        }

        public async Task<WorkoutPlan?> GetActiveByUserIdAsync(string userId)
        {
            return await _collection
                .Find(x => x.UserId == userId && x.IsActive)
                .FirstOrDefaultAsync();
        }

        public async Task DeactivateAllByUserIdAsync(string userId)
        {
            if (string.IsNullOrWhiteSpace(userId))
            {
                return;
            }

            var update = Builders<WorkoutPlan>.Update
                .Set(x => x.IsActive, false);

            var filter = Builders<WorkoutPlan>.Filter.And(
                Builders<WorkoutPlan>.Filter.Eq(x => x.UserId, userId),
                Builders<WorkoutPlan>.Filter.Eq(x => x.IsActive, true));

            await _collection.UpdateManyAsync(
                filter,
                update);
        }
    }
}
