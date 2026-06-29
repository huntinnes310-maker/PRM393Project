using GymSupport.Repository.Models.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Interfaces
{
    public interface IWorkoutSessionLogRepository
    {
        Task<WorkoutSessionLog> CreateAsync(WorkoutSessionLog sessionLog);

        Task<WorkoutSessionLog?> GetByIdAsync(string id);

        Task<WorkoutSessionLog?> GetActiveByUserIdAsync(string userId);

        Task<List<WorkoutSessionLog>> GetByUserIdAsync(string userId);

        Task UpdateAsync(string id, WorkoutSessionLog sessionLog);

        Task<List<WorkoutSessionLog>> GetAllAsync();

        Task<List<WorkoutSessionLog>> GetByDateRangeAsync(DateTime from, DateTime to);
    }
}
