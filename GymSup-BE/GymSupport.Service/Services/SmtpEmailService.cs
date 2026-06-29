using GymSupport.Service.Interfaces;
using Microsoft.Extensions.Configuration;
using System;
using System.IO;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;

namespace GymSupport.Service.Services
{
    public class SmtpEmailService : IEmailService
    {
        private readonly IConfiguration _config;
        private const string EmailTemplatePath = "Templates/EmailVerificationTemplate.html";

        public SmtpEmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task SendEmailVerificationAsync(string email, string verificationUrl)
        {
            var smtpHost = _config["Smtp:Host"];
            if (string.IsNullOrWhiteSpace(smtpHost))
            {
                Console.WriteLine("[Email] SMTP is not configured. Verification link:");
                Console.WriteLine($"To: {email}");
                Console.WriteLine($"{verificationUrl}");
                return;
            }

            var smtpPort = int.TryParse(_config["Smtp:Port"], out var port) ? port : 25;
            var enableSsl = bool.TryParse(_config["Smtp:EnableSsl"], out var ssl) && ssl;
            var fromAddress = _config["Smtp:From"] ?? _config["Smtp:Username"] ?? "no-reply@example.com";
            var subject = "Verify your email";
            var body = await BuildEmailBodyAsync(verificationUrl);

            var smtpUser = _config["Smtp:Username"];
            var smtpPass = _config["Smtp:Password"];

            using var message = new MailMessage(fromAddress, email, subject, body)
            {
                IsBodyHtml = true
            };
            using var client = new SmtpClient(smtpHost, smtpPort)
            {
                EnableSsl = enableSsl
            };

            if (!string.IsNullOrWhiteSpace(smtpUser))
            {
                client.Credentials = new NetworkCredential(smtpUser, smtpPass);
            }

            await client.SendMailAsync(message);
        }

        private async Task<string> BuildEmailBodyAsync(string verificationUrl)
        {
            var templateFile = Path.Combine(AppContext.BaseDirectory, EmailTemplatePath.Replace('/', Path.DirectorySeparatorChar));
            if (File.Exists(templateFile))
            {
                var template = await File.ReadAllTextAsync(templateFile);
                return template.Replace("{{VERIFICATION_URL}}", verificationUrl, StringComparison.Ordinal);
            }

            return $"<html><body><p>Welcome! Please verify your email by clicking the link below:</p><p><a href='{verificationUrl}'>Verify</a></p><p>This link is valid for 10 minutes.</p></body></html>";
        }
    }
}
