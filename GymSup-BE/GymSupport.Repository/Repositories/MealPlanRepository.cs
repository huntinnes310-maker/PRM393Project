using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class MealPlanRepository : IMealPlanRepository
{
    private readonly IMongoCollection<MealPlan> _collection;

    public MealPlanRepository(MongoDbContext context)
    {
        _collection = context.GetCollection<MealPlan>("MealPlans");
    }

    public async Task<List<MealPlan>> GetByDateRangeAsync(DateTime from, DateTime to)
    {
        return await _collection
            .Find(x => x.Date >= from && x.Date < to)
            .SortBy(x => x.Date)
            .ToListAsync();
    }
}
