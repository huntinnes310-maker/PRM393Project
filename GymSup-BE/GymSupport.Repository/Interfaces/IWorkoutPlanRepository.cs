using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IWorkoutPlanRepository
{
    Task<List<WorkoutPlan>> GetAllAsync();

    Task<WorkoutPlan?> GetByIdAsync(string id);

    Task<List<WorkoutPlan>> GetByUserIdAsync(string userId);

    Task CreateAsync(WorkoutPlan plan);

    Task UpdateAsync(WorkoutPlan plan);

    Task DeleteAsync(string id);

    Task<WorkoutPlan?> GetActiveByUserIdAsync(string userId);

    Task DeactivateAllByUserIdAsync(string userId);
}