using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using MongoDB.Driver;

namespace GymSupport.Repository.Repositories;

public class ExerciseRepository : IExerciseRepository
{
    private readonly IMongoCollection<Exercise> _exercises;

    public ExerciseRepository(MongoDbContext context)
    {
        _exercises = context.GetCollection<Exercise>("Exercises");
    }

    public async Task<IEnumerable<Exercise>> GetAllAsync()
    {
        return await _exercises
            .Find(_ => true)
            .ToListAsync();
    }

    public async Task<Exercise?> GetByIdAsync(string id)
    {
        return await _exercises
            .Find(x => x.Id == id)
            .FirstOrDefaultAsync();
    }
    public async Task<Exercise?> GetByNameAsync(
    string name)
    {
        return await _exercises
            .Find(x => x.Name == name)
            .FirstOrDefaultAsync();
    }
    public Task CreateAsync(Exercise exercise)
    {
        return _exercises.InsertOneAsync(exercise);
    }

    public Task UpdateAsync(Exercise exercise)
    {
        return _exercises.ReplaceOneAsync(
            x => x.Id == exercise.Id,
            exercise);
    }

    public Task DeleteAsync(string id)
    {
        return _exercises.DeleteOneAsync(
            x => x.Id == id);
    }
}