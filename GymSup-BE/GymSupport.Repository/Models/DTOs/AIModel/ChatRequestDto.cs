using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.AIModel
{
    public class ChatRequestDto
    {
        public string UserId { get; set; } = "";

        public string Message { get; set; } = "";
    }
}
