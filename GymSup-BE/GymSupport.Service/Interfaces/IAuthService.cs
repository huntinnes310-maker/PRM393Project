using GymSupport.Repository.Models.DTOs.Auth;
using System.Threading.Tasks;

namespace GymSupport.Service.Interfaces
{
    public interface IAuthService
    {
        Task<(string userId, bool isNewRegistration)> RegisterCustomerAsync(RegisterCustomerRequest req);
        Task<(string userId, bool isNewRegistration)> RegisterManagerAsync(RegisterManagerRequest req);
        Task<AuthResponse> LoginAsync(LoginRequest req);
        Task VerifyEmailAsync(string userId, string token);
        Task ResendVerificationEmailAsync(string email);
    }
}
