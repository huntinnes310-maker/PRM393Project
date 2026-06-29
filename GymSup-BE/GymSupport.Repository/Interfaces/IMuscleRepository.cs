using GymSupport.Repository.Models.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Interfaces
{
    public interface IMuscleRepository
    {
        Task<List<Muscle>> GetAllAsync();

        Task<Muscle?> GetByIdAsync(string id);

        Task CreateAsync(Muscle muscle);

        Task UpdateAsync(Muscle muscle);

        Task DeleteAsync(string id);

        Task<List<Muscle>> GetByCategoryAsync(string category);

    }
}
