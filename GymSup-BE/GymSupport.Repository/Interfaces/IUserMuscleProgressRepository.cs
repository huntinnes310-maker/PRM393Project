using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IUserMuscleProgressRepository
{
    Task<List<UserMuscleProgress>> GetByUserIdAsync(string userId);

    Task<UserMuscleProgress?> GetByUserAndMuscleAsync(string userId, string muscleId);

    Task UpsertAsync(UserMuscleProgress progress);
}
