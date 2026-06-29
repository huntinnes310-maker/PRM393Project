using System.Threading.Tasks;

namespace GymSupport.Service.Interfaces
{
    public interface IEmailService
    {
        Task SendEmailVerificationAsync(string email, string verificationUrl);
    }
}
