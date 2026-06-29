using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Bson;
using MongoDB.Driver;
using System.Text.RegularExpressions;

namespace GymSupport.Repository.Repositories;

public class MuscleRepository : IMuscleRepository
{
    private readonly IMongoCollection<Muscle> _collection;

    public MuscleRepository(
        MongoDbContext context)
    {
        _collection =
            context.GetCollection<Muscle>(
                "Muscles");
    }

    public async Task<List<Muscle>> GetAllAsync()
    {
        return await _collection
            .Find(_ => true)
            .ToListAsync();
    }

    public async Task<Muscle?> GetByIdAsync(
        string id)
    {
        return await _collection
            .Find(x => x.Id == id)
            .FirstOrDefaultAsync();
    }

    public async Task CreateAsync(
        Muscle muscle)
    {
        await _collection
            .InsertOneAsync(muscle);
    }

    public async Task UpdateAsync(
        Muscle muscle)
    {
        await _collection.ReplaceOneAsync(
            x => x.Id == muscle.Id,
            muscle);
    }

    public async Task DeleteAsync(
        string id)
    {
        await _collection.DeleteOneAsync(
            x => x.Id == id);
    }

    public async Task<List<Muscle>> GetByCategoryAsync(string category)
    {
        if (string.IsNullOrWhiteSpace(category))
            return new List<Muscle>();

        var normalizedCategory = category.Trim();

        var escapedCategory = Regex.Escape(normalizedCategory);

        var filter = Builders<Muscle>.Filter.Regex(
            x => x.Category,
            new BsonRegularExpression($"^{escapedCategory}$", "i")
        );

        return await _collection.Find(filter).ToListAsync();
    }
}