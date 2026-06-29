using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Bson;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class UserMuscleProgressRepository : IUserMuscleProgressRepository
{
    private readonly IMongoCollection<UserMuscleProgress> _collection;

    public UserMuscleProgressRepository(MongoDbContext context)
    {
        _collection = context.GetCollection<UserMuscleProgress>("UserMuscleProgress");
    }

    public async Task<List<UserMuscleProgress>> GetByUserIdAsync(string userId)
    {
        return await _collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.TotalExp)
            .ToListAsync();
    }

    public async Task<UserMuscleProgress?> GetByUserAndMuscleAsync(string userId, string muscleId)
    {
        return await _collection
            .Find(x => x.UserId == userId && x.MuscleId == muscleId)
            .FirstOrDefaultAsync();
    }

    public async Task UpsertAsync(UserMuscleProgress progress)
    {
        if (!ObjectId.TryParse(progress.Id, out _))
        {
            progress.Id = ObjectId.GenerateNewId().ToString();
        }

        progress.UpdatedAt = DateTime.UtcNow;

        await _collection.ReplaceOneAsync(
            x => x.UserId == progress.UserId && x.MuscleId == progress.MuscleId,
            progress,
            new ReplaceOptions { IsUpsert = true });
    }
}
