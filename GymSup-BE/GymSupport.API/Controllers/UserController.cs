using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.User;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace GymSupport.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    //[Authorize]
    public class UserController : ControllerBase
    {
        private readonly IUserRepository _userRepository;

        public UserController(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var users = await _userRepository.GetAllAsync();
            return Ok(users.Select(MapUser));
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id)
        {
            var user = await _userRepository.GetByIdAsync(id);
            if (user == null)
                return NotFound();

            return Ok(MapUser(user));
        }

        private static object MapUser(User user)
        {
            return new
            {
                user.Id,
                user.FullName,
                user.Email,
                user.Role,
                user.IsActive,
                user.CreatedAt,
                user.IsEmailVerified,
                user.VerifiedAt
            };
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, [FromBody] UpdateUserRequest request)
        {
            var user = await _userRepository.GetByIdAsync(id);
            if (user == null)
                return NotFound();

            if (!string.IsNullOrWhiteSpace(request.FullName))
                user.FullName = request.FullName;

            if (!string.IsNullOrWhiteSpace(request.Email))
                user.Email = request.Email;

            if (!string.IsNullOrWhiteSpace(request.Role))
                user.Role = request.Role;

            if (request.IsActive.HasValue)
                user.IsActive = request.IsActive.Value;

            await _userRepository.UpdateAsync(user);
            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            var user = await _userRepository.GetByIdAsync(id);
            if (user == null)
                return NotFound();

            await _userRepository.DeleteAsync(id);
            return NoContent();
        }

        [HttpPut("{id}/activate")]
        public async Task<IActionResult> Activate(string id)
        {
            var user = await _userRepository.GetByIdAsync(id);
            if (user == null)
                return NotFound();

            user.IsActive = true;
            await _userRepository.UpdateAsync(user);
            return NoContent();
        }

        [HttpPut("{id}/deactivate")]
        public async Task<IActionResult> Deactivate(string id)
        {
            var user = await _userRepository.GetByIdAsync(id);
            if (user == null)
                return NotFound();

            user.IsActive = false;
            await _userRepository.UpdateAsync(user);
            return NoContent();
        }
    }
}
