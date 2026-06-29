using GymSupport.Repository.Models.Entities;
using System;

namespace GymSupport.Service.Interfaces
{
    public interface ITokenService
    {
        string CreateToken(User user);
    }
}
