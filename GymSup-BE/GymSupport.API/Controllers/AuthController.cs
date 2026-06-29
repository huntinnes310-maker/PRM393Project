using GymSupport.Repository.Models.DTOs.Auth;
using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.IO;
using System.Security.Claims;

namespace GymSupport.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("register/customer")]
        public async Task<IActionResult> RegisterCustomer([FromBody] RegisterCustomerRequest request)
        {
            try
            {
                var (userId, isNewRegistration) = await _authService.RegisterCustomerAsync(request);
                if (isNewRegistration)
                    return CreatedAtAction(nameof(RegisterCustomer), new { id = userId }, new { id = userId });

                return Ok(new { message = "Email already registered but not verified. Verification email resent.", id = userId });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
        }

        [HttpPost("register/manager")]
        public async Task<IActionResult> RegisterManager([FromBody] RegisterManagerRequest request)
        {
            try
            {
                var (userId, isNewRegistration) = await _authService.RegisterManagerAsync(request);
                if (isNewRegistration)
                    return CreatedAtAction(nameof(RegisterManager), new { id = userId }, new { id = userId });

                return Ok(new { message = "Email already registered but not verified. Verification email resent.", id = userId });
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                var resp = await _authService.LoginAsync(request);
                return Ok(resp);
            }
            catch (UnauthorizedAccessException)
            {
                return Unauthorized(new { message = "Invalid credentials." });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("resend-verification")]
        public async Task<IActionResult> ResendVerification([FromBody] ResendVerificationRequest request)
        {
            try
            {
                await _authService.ResendVerificationEmailAsync(request.Email);
                return Ok(new { message = "Verification email resent." });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("verify-email")]
        public async Task<IActionResult> VerifyEmail([FromQuery] string userId, [FromQuery] string token)
        {
            try
            {
                await _authService.VerifyEmailAsync(userId, token);

                var templatePath = Path.Combine(AppContext.BaseDirectory, "Templates", "VerifySuccess.html");
                if (System.IO.File.Exists(templatePath))
                {
                    var html = await System.IO.File.ReadAllTextAsync(templatePath);
                    return Content(html, "text/html");
                }

                return Content("<html><body><h1>Xác minh thành công</h1><p>Email của bạn đã được xác thực.</p></body></html>", "text/html");
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [Authorize]
        [HttpGet("me")]
        public IActionResult Me()
        {
            var userId = User.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier) 
                ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);
            return Ok(new { userId });
        }
    }
}