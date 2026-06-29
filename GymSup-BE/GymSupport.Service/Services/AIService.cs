//using GymSupport.Repository.Interfaces;
//using GymSupport.Repository.Models.DTOs.AIModel;
//using GymSupport.Service.Interfaces;
//using GymSupport.Service.Services;
//namespace GymSupport.Service.Services;

//public class AIService : IAIService
//{
//    private readonly IWorkoutPlanRepository _workoutRepo;

//    public AIService(
//        IWorkoutPlanRepository workoutRepo)
//    {
//        _workoutRepo = workoutRepo;
//    }

//    public async Task<ChatResponseDto> ChatAsync(
//        string userId,
//        string message)
//    {
//        var plans =
//            await _workoutRepo.GetByUserIdAsync(userId);

//        if (message.ToLower().Contains("lịch tập"))
//        {
//            return new ChatResponseDto
//            {
               
//                Message =
//                    $"Bạn hiện có {plans.Count} lịch tập."
//            };
//        }

//        if (message.ToLower().Contains("ngực"))
//        {
//            return new ChatResponseDto
//            {
               
//                Message =
//                    "Bạn nên tập Bench Press, Incline Press, Cable Fly."
//            };
//        }

//        return new ChatResponseDto
//        {
            
//            Message = "Tôi chưa hiểu yêu cầu."
//        };
//    }
//}