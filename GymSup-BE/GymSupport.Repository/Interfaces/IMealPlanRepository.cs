using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IMealPlanRepository
{
    Task<List<MealPlan>> GetByDateRangeAsync(DateTime from, DateTime to);
}
