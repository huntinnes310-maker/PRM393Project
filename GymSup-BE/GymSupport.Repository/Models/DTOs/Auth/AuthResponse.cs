using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.Auth
{
    public class AuthResponse
    {
        public string Token { get; set; }
        public string UserId { get; set; }
        public string Role { get; set; }
    }
}
