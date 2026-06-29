using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class ChatRepository : IChatRepository
{
    private readonly IMongoCollection<ChatMessage> _collection;

    public ChatRepository(MongoDbContext context)
    {
        _collection = context.ChatMessages;
    }

    public async Task CreateAsync(
        ChatMessage message)
    {
        await _collection.InsertOneAsync(message);
    }
    public async Task<List<ChatMessage>>
    GetByUserIdAsync(
        string userId)
    {
        return await _collection
            .Find(x => x.UserId == userId)
            .SortBy(x => x.CreatedAt)
            .ToListAsync();
    }
    public async Task<List<ChatMessage>>
        GetRecentMessagesAsync(
            string userId,
            int count = 20)
    {
        return await _collection
            .Find(x => x.UserId == userId)
            .SortByDescending(x => x.CreatedAt)
            .Limit(count)
            .ToListAsync();
    }

    public async Task DeleteByUserIdAsync(string userId)
    {
        await _collection.DeleteManyAsync(x => x.UserId == userId);
    }

    public async Task<List<ChatMessage>> GetByDateRangeAsync(DateTime from, DateTime to)
    {
        return await _collection
            .Find(x => x.CreatedAt >= from && x.CreatedAt < to)
            .SortBy(x => x.CreatedAt)
            .ToListAsync();
    }
}