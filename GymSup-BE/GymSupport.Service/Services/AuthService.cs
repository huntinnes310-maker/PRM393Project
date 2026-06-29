using GymSupport.Repository.Models.DTOs.Auth;
using GymSupport.Repository.Models.Entities;
using GymSupport.Repository.Interfaces;
using GymSupport.Service.Interfaces;
using Microsoft.Extensions.Configuration;
using MongoDB.Bson;
using System;
using System.Security.Cryptography;
using System.Threading.Tasks;

namespace GymSupport.Service.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _repo;
        private readonly ICustomerRepository _customerRepository;
        private readonly IUserSubscriptionRepository _userSubscriptionRepository;
        private readonly ITokenService _tokenService;
        private readonly IEmailService _emailService;
        private readonly IConfiguration _config;
        private readonly TimeSpan _verificationLifetime = TimeSpan.FromMinutes(10);

        public AuthService(
            IUserRepository repo,
            ICustomerRepository customerRepository,
            IUserSubscriptionRepository userSubscriptionRepository,
            ITokenService tokenService,
            IEmailService emailService,
            IConfiguration config)
        {
            _repo = repo;
            _customerRepository = customerRepository;
            _userSubscriptionRepository = userSubscriptionRepository;
            _tokenService = tokenService;
            _emailService = emailService;
            _config = config;
        }

        public async Task<(string userId, bool isNewRegistration)> RegisterCustomerAsync(RegisterCustomerRequest req)
        {
            var existing = await _repo.GetByEmailAsync(req.Email);
            if (existing != null)
            {
                if (existing.IsEmailVerified)
                    throw new InvalidOperationException("Email already in use.");

                await RefreshVerificationTokenAsync(existing);
                await SendVerificationEmailAsync(existing);
                return (existing.Id, false);
            }

            var hash = BCrypt.Net.BCrypt.HashPassword(req.Password);
            var user = new User
            {
                Id = ObjectId.GenerateNewId().ToString(),
                FullName = req.FullName,
                Email = req.Email,
                PasswordHash = hash,
                Role = "Customer",
                CreatedAt = DateTime.UtcNow,
                IsEmailVerified = false
            };

            AssignVerificationToken(user);
            await _repo.CreateAsync(user);
            await _customerRepository.CreateAsync(new Customer
            {
                UserId = user.Id,
                HeightCm = 0,
                WeightKg = 0,
                Goal = null,
                ExperienceLevel = null,
                InjuryNotes = null
            });
            await SendVerificationEmailAsync(user);
            return (user.Id, true);
        }

        public async Task<(string userId, bool isNewRegistration)> RegisterManagerAsync(RegisterManagerRequest req)
        {
            var existing = await _repo.GetByEmailAsync(req.Email);
            if (existing != null)
            {
                if (existing.IsEmailVerified)
                    throw new InvalidOperationException("Email already in use.");

                await RefreshVerificationTokenAsync(existing);
                await SendVerificationEmailAsync(existing);
                return (existing.Id, false);
            }

            var hash = BCrypt.Net.BCrypt.HashPassword(req.Password);
            var user = new User
            {
                FullName = req.FullName,
                Email = req.Email,
                PasswordHash = hash,
                Role = "Manager",
                CreatedAt = DateTime.UtcNow,
                IsEmailVerified = false
            };

            AssignVerificationToken(user);
            await _repo.CreateAsync(user);
            await SendVerificationEmailAsync(user);
            return (user.Id, true);
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest req)
        {
            var user = await _repo.GetByEmailAsync(req.Email);
            if (user == null)
                throw new UnauthorizedAccessException();

            if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
                throw new UnauthorizedAccessException();

            if (!user.IsEmailVerified)
                throw new InvalidOperationException("Email address has not been verified.");

            var token = _tokenService.CreateToken(user);
            return new AuthResponse
            {
                Token = token,
                UserId = user.Id,
                Role = user.Role
            };
        }

        public async Task VerifyEmailAsync(string userId, string token)
        {
            var user = await _repo.GetByIdAsync(userId);
            if (user == null)
                throw new InvalidOperationException("Invalid verification request.");

            if (user.IsEmailVerified)
                throw new InvalidOperationException("Email already verified.");

            if (string.IsNullOrEmpty(user.EmailVerificationToken) || user.EmailVerificationTokenExpiresAt == null)
                throw new InvalidOperationException("Invalid verification token.");

            if (!string.Equals(user.EmailVerificationToken, token, StringComparison.Ordinal))
                throw new InvalidOperationException("Invalid verification token.");

            if (user.EmailVerificationTokenExpiresAt.Value < DateTime.UtcNow)
                throw new InvalidOperationException("Verification token has expired.");

            user.IsEmailVerified = true;
            user.VerifiedAt = DateTime.UtcNow;
            user.EmailVerificationToken = null;
            user.EmailVerificationTokenExpiresAt = null;

            await _repo.UpdateAsync(user);
            
            // Create free subscription for verified user
            var existingSubscription = await _userSubscriptionRepository.GetByUserIdAsync(userId);
            if (existingSubscription == null)
            {
                await _userSubscriptionRepository.CreateAsync(new UserSubscription
                {
                    UserId = userId,
                    PlanId = string.Empty,
                    PlanName = "free",
                    Price = 0,
                    Status = "Active",
                    StartedAt = DateTime.UtcNow,
                    ExpiredAt = null
                });
            }
        }

        public async Task ResendVerificationEmailAsync(string email)
        {
            var user = await _repo.GetByEmailAsync(email);
            if (user == null)
                throw new InvalidOperationException("Email not found.");

            if (user.IsEmailVerified)
                throw new InvalidOperationException("Email already verified.");

            await RefreshVerificationTokenAsync(user);
            await SendVerificationEmailAsync(user);
        }

        private static string GenerateVerificationToken()
        {
            var bytes = new byte[32];
            RandomNumberGenerator.Fill(bytes);
            return Convert.ToBase64String(bytes)
                .TrimEnd('=')
                .Replace('+', '-')
                .Replace('/', '_');
        }

        private void AssignVerificationToken(User user)
        {
            user.EmailVerificationToken = GenerateVerificationToken();
            user.EmailVerificationTokenExpiresAt = DateTime.UtcNow.Add(_verificationLifetime);
        }

        private async Task RefreshVerificationTokenAsync(User user)
        {
            AssignVerificationToken(user);
            await _repo.UpdateAsync(user);
        }

        private async Task SendVerificationEmailAsync(User user)
        {
            if (string.IsNullOrEmpty(user.EmailVerificationToken))
                throw new InvalidOperationException("Verification token is missing.");

            var verificationUrl = BuildVerificationUrl(user.Id, user.EmailVerificationToken);
            await _emailService.SendEmailVerificationAsync(user.Email, verificationUrl);
        }

        private string BuildVerificationUrl(string userId, string token)
        {
            var baseUrl = _config["App:BaseUrl"]?.TrimEnd('/') ?? "https://localhost:5001";
            return $"{baseUrl}/api/auth/verify-email?userId={Uri.EscapeDataString(userId)}&token={Uri.EscapeDataString(token)}";
        }
    }
}
