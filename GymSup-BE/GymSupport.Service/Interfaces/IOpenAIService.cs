using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Service.Interfaces
{
    public interface IOpenAIService
    {
        Task<string> AskAsync(string prompt);
    }
}
