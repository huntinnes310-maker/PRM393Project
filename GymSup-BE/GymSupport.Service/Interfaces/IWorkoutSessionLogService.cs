using GymSupport.Repository.Models.DTOs.WorkoutPlan;
using GymSupport.Repository.Models.Entities;
namespace GymSupport.Service.Interfaces;

public interface IWorkoutSessionLogService
{
    Task<WorkoutSessionLog> StartSessionAsync(
        StartWorkoutSessionRequestDto dto);

    Task<WorkoutSessionLog?> GetActiveSessionAsync(
        string userId);

    Task<WorkoutSessionLog> AddSetAsync(
        string sessionLogId,
        string exerciseLogId,
        AddWorkoutSetRequestDto dto);

    Task<WorkoutSessionLog> FinishSessionAsync(
        string sessionLogId);

    Task<List<WorkoutSessionLog>> GetHistoryAsync(
        string userId);

    Task<(int currentStreak, UserBadge? newBadge)> CheckAndAwardStreakBadgeAsync(
        string userId);
}