namespace GymSupport.Repository.Models.DTOs.User
{
    public class UpdateUserRequest
    {
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? Role { get; set; }
        public bool? IsActive { get; set; }
    }
}
