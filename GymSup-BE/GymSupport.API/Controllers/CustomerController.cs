using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.Customer;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace GymSupport.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CustomerController : ControllerBase
    {
        private readonly ICustomerRepository _customerRepository;
        private readonly IUserRepository _userRepository;
        private readonly IWorkoutPlanRepository _workoutPlanRepository;
        private readonly IExerciseRepository _exerciseRepository;

        public CustomerController(
            ICustomerRepository customerRepository, 
            IUserRepository userRepository,
            IWorkoutPlanRepository workoutPlanRepository,
            IExerciseRepository exerciseRepository)
        {
            _customerRepository = customerRepository;
            _userRepository = userRepository;
            _workoutPlanRepository = workoutPlanRepository;
            _exerciseRepository = exerciseRepository;
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetByUserId(string userId)
        {
            var currentUser = await GetActiveUserAsync();
            if (currentUser == null)
                return Forbid();

            if (currentUser.Id != userId && currentUser.Role != "Admin")
                return Forbid();

            var customer = await _customerRepository.GetByUserIdAsync(userId);
            if (customer == null)
                return NotFound(new { message = "Customer profile not found" });

            var user = await _userRepository.GetByIdAsync(userId);

            var response = new CustomerProfileResponseDto
            {
                Id = customer.Id,
                UserId = customer.UserId,

                FullName = user?.FullName ?? "",
                Email = user?.Email ?? "",

                Gender = customer.Gender,
                Age = customer.Age,
                Bmi = customer.Bmi,
                HeightCm = customer.HeightCm,
                WeightKg = customer.WeightKg,
                Goal = customer.Goal,
                ExperienceLevel = customer.ExperienceLevel,
                InjuryNotes = customer.InjuryNotes
            };

            return Ok(response);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateCustomerRequest request)
        {
            var currentUser = await GetActiveUserAsync();
            if (currentUser == null)
                return Forbid();

            if (currentUser.Id != request.UserId && currentUser.Role != "Admin")
                return Forbid();

            var existing = await _customerRepository.GetByUserIdAsync(request.UserId);
            if (existing != null)
                return Conflict(new { message = "Customer record already exists for this user." });

            var customer = new Customer
            {
                UserId = request.UserId,
                Gender = request.Gender,
                Age = request.Age ?? 0,
                HeightCm = request.HeightCm ?? 0,
                WeightKg = request.WeightKg ?? 0,
                Goal = request.Goal,
                ExperienceLevel = request.ExperienceLevel,
                InjuryNotes = request.InjuryNotes
            };
            customer.Bmi = CalculateBmi(customer.WeightKg, customer.HeightCm);

            await _customerRepository.CreateAsync(customer);

            // Tự động sinh lịch tập mặc định nếu chưa có
            if (!string.IsNullOrWhiteSpace(customer.Goal))
            {
                await GenerateDefaultPlanIfNeededAsync(customer.UserId, customer.Goal);
            }

            return CreatedAtAction(nameof(GetByUserId), new { userId = customer.UserId }, customer);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(string id, [FromBody] UpdateCustomerInfoRequest request)
        {
            var currentUser = await GetActiveUserAsync();
            if (currentUser == null)
                return Forbid();

            var customer = await _customerRepository.GetByIdAsync(id);
            if (customer == null)
                return NotFound();

            if (currentUser.Id != customer.UserId && currentUser.Role != "Admin")
                return Forbid();

            if (request.Gender != null)
                customer.Gender = request.Gender;

            if (request.Age.HasValue)
                customer.Age = request.Age.Value;

            if (request.HeightCm.HasValue)
                customer.HeightCm = request.HeightCm.Value;

            if (request.WeightKg.HasValue)
                customer.WeightKg = request.WeightKg.Value;

            customer.Bmi = CalculateBmi(customer.WeightKg, customer.HeightCm);

            if (request.Goal != null)
                customer.Goal = request.Goal;

            if (request.ExperienceLevel != null)
                customer.ExperienceLevel = request.ExperienceLevel;

            if (request.InjuryNotes != null)
                customer.InjuryNotes = request.InjuryNotes;

            await _customerRepository.UpdateAsync(customer);

            // Tự động sinh lịch tập mặc định nếu chưa có
            if (!string.IsNullOrWhiteSpace(customer.Goal))
            {
                await GenerateDefaultPlanIfNeededAsync(customer.UserId, customer.Goal);
            }

            return NoContent();
        }

        private async Task GenerateDefaultPlanIfNeededAsync(string userId, string goal)
        {
            try
            {
                var existingPlans = await _workoutPlanRepository.GetByUserIdAsync(userId);
                if (existingPlans != null && existingPlans.Any())
                    return; // Đã có lịch tập rồi, không sinh nữa

                var plan = new WorkoutPlan
                {
                    UserId = userId,
                    Name = GetPlanNameForGoal(goal),
                    Goal = goal,
                    Description = "Lịch tập 3 buổi mỗi tuần được thiết lập tự động dựa trên mục tiêu thể trạng của bạn.",
                    DaysPerWeek = 3,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    Sessions = new List<WorkoutSession>()
                };

                var allExercises = (await _exerciseRepository.GetAllAsync()).ToList();

                // Thứ 2: Ngực & Tay sau
                var monSession = new WorkoutSession
                {
                    Id = Guid.NewGuid().ToString(),
                    DayOfWeek = "Monday",
                    Focus = "Ngực & Tay sau",
                    Exercises = new List<ExerciseInSession>()
                };
                AddExerciseToSession(monSession, allExercises, "Barbell Bench Press", 4, "8-10");
                AddExerciseToSession(monSession, allExercises, "Incline Dumbbell Press", 3, "10-12");
                AddExerciseToSession(monSession, allExercises, "Push-Up", 3, "12-15");
                AddExerciseToSession(monSession, allExercises, "Rope Pushdown", 3, "12-15");
                plan.Sessions.Add(monSession);

                // Thứ 4: Lưng xô & Tay trước
                var wedSession = new WorkoutSession
                {
                    Id = Guid.NewGuid().ToString(),
                    DayOfWeek = "Wednesday",
                    Focus = "Lưng xô & Tay trước",
                    Exercises = new List<ExerciseInSession>()
                };
                AddExerciseToSession(wedSession, allExercises, "Pull-Up", 4, "6-10");
                AddExerciseToSession(wedSession, allExercises, "Wide-Grip Lat Pulldown", 3, "10-12");
                AddExerciseToSession(wedSession, allExercises, "Barbell Bent-Over Row", 3, "8-10");
                AddExerciseToSession(wedSession, allExercises, "Barbell Curl", 3, "10-12");
                plan.Sessions.Add(wedSession);

                // Thứ 6: Chân & Vai
                var friSession = new WorkoutSession
                {
                    Id = Guid.NewGuid().ToString(),
                    DayOfWeek = "Friday",
                    Focus = "Chân & Vai",
                    Exercises = new List<ExerciseInSession>()
                };
                AddExerciseToSession(friSession, allExercises, "Barbell Overhead Press", 4, "8-10");
                AddExerciseToSession(friSession, allExercises, "Dumbbell Lateral Raise", 3, "12-15");
                AddExerciseToSession(friSession, allExercises, "Conventional Deadlift", 3, "5-8");
                plan.Sessions.Add(friSession);

                await _workoutPlanRepository.CreateAsync(plan);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"--> Error generating default plan: {ex.Message}");
            }
        }

        private static string GetPlanNameForGoal(string goal)
        {
            var lowerGoal = goal?.ToLowerInvariant() ?? "";
            if (lowerGoal.Contains("muscle") || lowerGoal.Contains("tăng cơ"))
                return "Kế hoạch Xây dựng Cơ bắp (3 ngày/tuần)";
            if (lowerGoal.Contains("lose") || lowerGoal.Contains("giảm mỡ") || lowerGoal.Contains("fat"))
                return "Kế hoạch Siết cơ Giảm mỡ (3 ngày/tuần)";
            if (lowerGoal.Contains("strength") || lowerGoal.Contains("sức mạnh"))
                return "Kế hoạch Tăng Sức mạnh Powerlifting";
            return "Lịch tập Toàn thân Tổng hợp";
        }

        private static void AddExerciseToSession(WorkoutSession session, List<Exercise> allExercises, string name, int sets, string reps)
        {
            var exercise = allExercises.FirstOrDefault(e => e.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
            if (exercise != null)
            {
                session.Exercises.Add(new ExerciseInSession
                {
                    ExerciseId = exercise.Id,
                    ExerciseName = exercise.Name,
                    Sets = sets,
                    Reps = reps,
                    Notes = "Thực hiện đúng kỹ thuật, chú ý nhịp thở."
                });
            }
        }

        private async Task<User?> GetActiveUserAsync()
        {
            var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(currentUserId))
                return null;

            var currentUser = await _userRepository.GetByIdAsync(currentUserId);
            if (currentUser == null)
                return null;

            return currentUser;
        }

        private static double CalculateBmi(int weightKg, int heightCm)
        {
            if (weightKg <= 0 || heightCm <= 0)
                return 0;

            var heightM = heightCm / 100.0;
            return Math.Round(weightKg / (heightM * heightM), 1);
        }
    }
}
