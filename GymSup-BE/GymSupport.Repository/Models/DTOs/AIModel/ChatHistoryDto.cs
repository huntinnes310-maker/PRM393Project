using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.AIModel
{
    public class ChatHistoryDto
    {
        public string Role { get; set; }

        public string Content { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
