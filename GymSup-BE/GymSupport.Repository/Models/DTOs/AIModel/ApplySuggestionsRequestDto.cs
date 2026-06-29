using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.AIModel
{
    public class ApplySuggestionsRequestDto
    {
        public string UserId { get; set; } = "";

        public List<AISuggestionDto> Suggestions { get; set; }
            = new();
    }
}
