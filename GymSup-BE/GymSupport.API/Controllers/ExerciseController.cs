using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.Exercise;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/exercises")]
public class ExercisesController : ControllerBase
{
    private readonly IExerciseRepository _repository;
    private readonly IMuscleRepository _muscleRepository;
    public ExercisesController(
       IExerciseRepository repository,
       IMuscleRepository muscleRepository)
    {
        _repository = repository;
        _muscleRepository = muscleRepository;
    }
    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? category,
        [FromQuery] string? muscleId)
    {
        var exercises = (await _repository.GetAllAsync()).ToList();

        if (!string.IsNullOrWhiteSpace(muscleId))
        {
            exercises = exercises
                .Where(e => e.MuscleImpacts.Any(mi => mi.MuscleId == muscleId))
                .ToList();

            return Ok(exercises);
        }

        if (!string.IsNullOrWhiteSpace(category))
        {
            var muscles = await _muscleRepository.GetAllAsync();

            var muscleIds = muscles
                .Where(m => string.Equals(m.Category, category, StringComparison.OrdinalIgnoreCase))
                .Select(m => m.Id)
                .ToHashSet();

            exercises = exercises
                .Where(e => e.MuscleImpacts.Any(mi => muscleIds.Contains(mi.MuscleId)))
                .ToList();

            return Ok(exercises);
        }

        return Ok(exercises);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(
        string id)
    {
        var exercise =
            await _repository.GetByIdAsync(id);

        if (exercise == null)
            return NotFound();

        return Ok(exercise);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(
        CreateExerciseDto dto)
    {
        var exercise =
            new Exercise
            {
                Name = dto.Name,
                Equipment = dto.Equipment,
                Difficulty = dto.Difficulty,
                Description = dto.Description ?? "",
                Instruction = dto.Instruction ?? "",
                SafetyNotes = dto.SafetyNotes ?? "",
                CommonMistakes = dto.CommonMistakes ?? "",
                Tips = dto.Tips ?? "",
                DefaultSets = dto.DefaultSets <= 0 ? 3 : dto.DefaultSets,
                DefaultReps = string.IsNullOrWhiteSpace(dto.DefaultReps) ? "10" : dto.DefaultReps,
                RestTimeSeconds = dto.RestTimeSeconds <= 0 ? 60 : dto.RestTimeSeconds,
                ImageUrl = dto.ImageUrl,
                VideoUrl = dto.VideoUrl,

                MuscleImpacts =
                    dto.MuscleImpacts
                        .Select(x =>
                            new MuscleImpact
                            {
                                MuscleId =
                                    x.MuscleId,

                                Percentage =
                                    x.Percentage
                            })
                        .ToList()
            };

        await _repository.CreateAsync(
            exercise);

        return Ok(exercise);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(
        string id,
        CreateExerciseDto dto)
    {
        var exercise =
            await _repository.GetByIdAsync(id);

        if (exercise == null)
            return NotFound();

        exercise.Name = dto.Name;
        exercise.Equipment = dto.Equipment;
        exercise.Difficulty = dto.Difficulty;
        exercise.Description = dto.Description ?? "";
        exercise.Instruction = dto.Instruction ?? "";
        exercise.SafetyNotes = dto.SafetyNotes ?? "";
        exercise.CommonMistakes = dto.CommonMistakes ?? "";
        exercise.Tips = dto.Tips ?? "";
        exercise.DefaultSets = dto.DefaultSets <= 0 ? 3 : dto.DefaultSets;
        exercise.DefaultReps = string.IsNullOrWhiteSpace(dto.DefaultReps) ? "10" : dto.DefaultReps;
        exercise.RestTimeSeconds = dto.RestTimeSeconds <= 0 ? 60 : dto.RestTimeSeconds;
        exercise.ImageUrl = dto.ImageUrl;
        exercise.VideoUrl = dto.VideoUrl;

        exercise.MuscleImpacts =
            dto.MuscleImpacts
                .Select(x =>
                    new MuscleImpact
                    {
                        MuscleId =
                            x.MuscleId,

                        Percentage =
                            x.Percentage
                    })
                .ToList();

        await _repository.UpdateAsync(
            exercise);

        return Ok(exercise);
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(
        string id)
    {
        var exercise =
            await _repository.GetByIdAsync(id);

        if (exercise == null)
            return NotFound();

        await _repository.DeleteAsync(id);

        return NoContent();
    }
}
