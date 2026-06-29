using GymSupport.Repository.Models.Entities;

namespace GymSupport.Repository.Interfaces;

public interface IUserBadgeRepository
{
    Task<List<UserBadge>> GetByUserIdAsync(string userId);

    Task<UserBadge?> GetByUserAndTypeAsync(string userId, string badgeType);

    Task<UserBadge> CreateAsync(UserBadge badge);
}
