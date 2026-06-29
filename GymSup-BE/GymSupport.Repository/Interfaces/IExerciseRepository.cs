using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IExerciseRepository
{
    Task<IEnumerable<Exercise>> GetAllAsync();

    Task<Exercise?> GetByIdAsync(string id);
    Task<Exercise?> GetByNameAsync(string name);
    Task CreateAsync(Exercise exercise);

    Task UpdateAsync(Exercise exercise);

    Task DeleteAsync(string id);

   
}