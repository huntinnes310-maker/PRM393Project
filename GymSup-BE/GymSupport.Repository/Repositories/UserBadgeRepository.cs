using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Bson;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class UserBadgeRepository : IUserBadgeRepository
{
    private readonly IMongoCollection<UserBadge> _collection;

    public UserBadgeRepository(MongoDbContext context)
    {
        _collection = context.GetCollection<UserBadge>("UserBadges");
    }

    public async Task<List<UserBadge>> GetByUserIdAsync(string userId)
    {
        return await _collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.EarnedAt)
            .ToListAsync();
    }

    public async Task<UserBadge?> GetByUserAndTypeAsync(string userId, string badgeType)
    {
        return await _collection
            .Find(x => x.UserId == userId && x.BadgeType == badgeType)
            .FirstOrDefaultAsync();
    }

    public async Task<UserBadge> CreateAsync(UserBadge badge)
    {
        if (!ObjectId.TryParse(badge.Id, out _))
        {
            badge.Id = ObjectId.GenerateNewId().ToString();
        }
        badge.EarnedAt = DateTime.UtcNow;
        await _collection.InsertOneAsync(badge);
        return badge;
    }
}
