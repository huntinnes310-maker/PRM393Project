using GymSupport.Repository.Models.DTOs.AIModel;

namespace GymSupport.Service.Interfaces;

public interface IAIService
{
    Task<ChatResponseDto> ChatAsync(
        string userId,
        string message);

    Task<ChatResponseDto> GenerateWorkoutPlanAsync(
        string userId,
        GenerateWorkoutPlanRequestDto request);

    Task ApplySuggestionsAsync(ApplySuggestionsRequestDto dto);

    Task<ImageAnalyzeResponseDto> AnalyzeImageAsync(
      string userId,
      Stream imageStream,
      string contentType,
      string mode);

    Task<VideoFormAnalyzeResponseDto> AnalyzeFormVideoAsync(
    string userId,
    Stream videoStream,
    string fileName,
    string contentType);

    Task<WorkoutEvaluationNarrativeDto> EvaluateWorkoutAsync(
        string userId,
        WorkoutEvaluationMetricsDto metrics);
}
