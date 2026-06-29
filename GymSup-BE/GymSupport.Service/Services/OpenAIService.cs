using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.DTOs.AIModel;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;
using Microsoft.Extensions.Configuration;
using System.Diagnostics;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;

namespace GymSupport.Service.Services;

public class OpenAIService : IAIService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly IChatRepository _chatRepository;
    private readonly IWorkoutPlanRepository _workoutRepository;
    private readonly IExerciseRepository _exerciseRepository;
    private readonly ICustomerRepository _customerRepository;
    private readonly IUserRepository _userRepository;

    public OpenAIService(
     HttpClient httpClient,
     IConfiguration configuration,
     IChatRepository chatRepository,
     IWorkoutPlanRepository workoutRepository,
     IExerciseRepository exerciseRepository,
     ICustomerRepository customerRepository,
     IUserRepository userRepository)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _chatRepository = chatRepository;
        _workoutRepository = workoutRepository;
        _exerciseRepository = exerciseRepository;
        _customerRepository = customerRepository;
        _userRepository = userRepository;
    }

    public async Task ApplySuggestionsAsync(ApplySuggestionsRequestDto dto)
    {
        string? newlyCreatedPlanId = null;
        var createdSessionIds = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        foreach (var suggestion in dto.Suggestions)
        {
            // 1. Ánh xạ PlanId nếu gặp ký tự giữ chỗ
            if (suggestion.PlanId == "{planId}" || string.IsNullOrWhiteSpace(suggestion.PlanId))
            {
                suggestion.PlanId = newlyCreatedPlanId;
            }

            // 2. Ánh xạ SessionId động dựa trên hậu tố ngày
            if (!string.IsNullOrEmpty(suggestion.SessionId) && suggestion.SessionId.StartsWith("{sessionId_"))
            {
                var dayKey = suggestion.SessionId
                    .Replace("{sessionId_", "")
                    .Replace("}", "")
                    .Trim();

                if (createdSessionIds.TryGetValue(dayKey, out var realSessionId))
                {
                    suggestion.SessionId = realSessionId;
                }
            }
            else if (suggestion.SessionId == "{sessionId}" && createdSessionIds.Any())
            {
                suggestion.SessionId = createdSessionIds.Last().Value;
            }

            // 3. Xử lý logic theo từng Action
            switch (suggestion.Action?.ToLower().Trim())
            {
                case "create_plan":
                    // NẾU TẠO LỊCH MỚI: Tắt toàn bộ lịch cũ của user trước để đảm bảo tính duy nhất của Active Plan
                    await _workoutRepository.DeactivateAllByUserIdAsync(dto.UserId);

                    var newPlan = new WorkoutPlan
                    {
                        UserId = dto.UserId,
                        Name = suggestion.PlanName,
                        Goal = suggestion.Goal,
                        Description = suggestion.PlanDescription,
                        DaysPerWeek = suggestion.DaysPerWeek,
                        IsActive = true, // Lịch mới luôn được ưu tiên kích hoạt
                        Sessions = new List<WorkoutSession>()
                    };

                    await _workoutRepository.CreateAsync(newPlan);
                    newlyCreatedPlanId = newPlan.Id;
                    break;

                case "create_session":
                    if (string.IsNullOrEmpty(suggestion.PlanId)) break;

                    var plan = await _workoutRepository.GetByIdAsync(suggestion.PlanId);
                    if (plan == null) break;

                    var newSession = new WorkoutSession
                    {
                        Id = Guid.NewGuid().ToString(),
                        DayOfWeek = suggestion.DayOfWeek,
                        Focus = suggestion.Focus,
                        Exercises = new List<ExerciseInSession>()
                    };

                    plan.Sessions.Add(newSession);
                    await _workoutRepository.UpdateAsync(plan);

                    if (!string.IsNullOrEmpty(suggestion.DayOfWeek))
                    {
                        createdSessionIds[suggestion.DayOfWeek.Trim()] = newSession.Id;
                    }
                    break;

                case "add_exercise":
                    if (string.IsNullOrEmpty(suggestion.PlanId) || string.IsNullOrEmpty(suggestion.SessionId)) break;

                    var workoutPlan = await _workoutRepository.GetByIdAsync(suggestion.PlanId);
                    if (workoutPlan == null) break;

                    var session = workoutPlan.Sessions.FirstOrDefault(x => x.Id == suggestion.SessionId);
                    if (session == null) break;

                    string dbExerciseName = "";
                    if (!string.IsNullOrEmpty(suggestion.ExerciseId))
                    {
                        var originalExercise = await _exerciseRepository.GetByIdAsync(suggestion.ExerciseId);
                        if (originalExercise != null)
                        {
                            dbExerciseName = originalExercise.Name; // Lấy tên thật từ danh mục bài tập (ví dụ: "Bench Press")
                        }
                    }
                    session.Exercises.Add(new ExerciseInSession
                    {
                        ExerciseId = suggestion.ExerciseId,
                        ExerciseName = dbExerciseName,
                        Sets = suggestion.Sets,
                        Reps = suggestion.Reps,
                        Notes = suggestion.Notes
                    });

                    await _workoutRepository.UpdateAsync(workoutPlan);
                    break;

                case "update_exercise":
                    if (string.IsNullOrEmpty(suggestion.PlanId) || string.IsNullOrEmpty(suggestion.SessionId) || string.IsNullOrEmpty(suggestion.ExerciseId))
                        break;

                    var uPlan = await _workoutRepository.GetByIdAsync(suggestion.PlanId);
                    if (uPlan == null) break;

                    var uSession = uPlan.Sessions.FirstOrDefault(x => x.Id == suggestion.SessionId);
                    if (uSession == null) break;

                    var targetEx = uSession.Exercises.FirstOrDefault(x => x.ExerciseId == suggestion.ExerciseId);
                    if (targetEx != null)
                    {
                        targetEx.Sets = suggestion.Sets;
                        targetEx.Reps = suggestion.Reps;
                        targetEx.Notes = suggestion.Notes;

                        await _workoutRepository.UpdateAsync(uPlan);
                    }
                    break;

                case "remove_exercise":
                    if (string.IsNullOrEmpty(suggestion.PlanId) || string.IsNullOrEmpty(suggestion.SessionId) || string.IsNullOrEmpty(suggestion.ExerciseId))
                        break;

                    var rPlan = await _workoutRepository.GetByIdAsync(suggestion.PlanId);
                    if (rPlan == null) break;

                    var rSession = rPlan.Sessions.FirstOrDefault(x => x.Id == suggestion.SessionId);
                    if (rSession == null) break;

                    // Tìm bài tập cần xóa dựa trên ExerciseId
                    var exToRemove = rSession.Exercises.FirstOrDefault(x => x.ExerciseId == suggestion.ExerciseId);
                    if (exToRemove != null)
                    {
                        rSession.Exercises.Remove(exToRemove); // Xóa khỏi danh sách
                        await _workoutRepository.UpdateAsync(rPlan); // Cập nhật lại vào MongoDB
                    }
                    break;

                default:
                    break;
            }
        }
    }

    public async Task<ChatResponseDto> GenerateWorkoutPlanAsync(
        string userId,
        GenerateWorkoutPlanRequestDto request)
    {
        var apiKey = _configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new Exception("OpenAI API key is missing.");
        }

        _httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);

        var customer = await _customerRepository.GetByUserIdAsync(userId);
        var user = await _userRepository.GetByIdAsync(userId);
        if (customer == null)
        {
            throw new Exception("Không tìm thấy hồ sơ người dùng để tạo lịch tập.");
        }

        var customerJson = JsonSerializer.Serialize(
            new
            {
                customer.Id,
                customer.UserId,
                FullName = user?.FullName ?? "",
                Email = user?.Email ?? "",
                customer.Gender,
                customer.Age,
                customer.Bmi,
                customer.HeightCm,
                customer.WeightKg,
                customer.Goal,
                customer.ExperienceLevel,
                customer.InjuryNotes
            },
            new JsonSerializerOptions { WriteIndented = true });

        var builderInputJson = JsonSerializer.Serialize(
            new
            {
                Goal = string.IsNullOrWhiteSpace(request.Goal) ? "AI Decide" : request.Goal,
                ExperienceLevel = string.IsNullOrWhiteSpace(request.ExperienceLevel) ? "AI Decide" : request.ExperienceLevel,
                DaysPerWeek = request.DaysPerWeek?.ToString() ?? "AI Decide",
                TrainingDays = request.TrainingDays.Count == 0
                    ? new[] { "AI Decide" }
                    : request.TrainingDays.ToArray(),
                Intensity = string.IsNullOrWhiteSpace(request.Intensity) ? "AI Decide" : request.Intensity,
                TrainingCondition = string.IsNullOrWhiteSpace(request.TrainingCondition) ? "AI Decide" : request.TrainingCondition,
                HealthIssues = string.IsNullOrWhiteSpace(request.HealthIssues) ? "Không khai báo" : request.HealthIssues
            },
            new JsonSerializerOptions { WriteIndented = true });

        var exercises = (await _exerciseRepository.GetAllAsync()).ToList();
        var exerciseJson = JsonSerializer.Serialize(
            exercises.Select(e => new
            {
                id = e.Id,
                name = e.Name,
                equipment = e.Equipment,
                difficulty = e.Difficulty
            }),
            new JsonSerializerOptions { WriteIndented = false });

        var messages = new List<object>
        {
            new
            {
                role = "system",
                content =
"""
Bạn là GymSupport AI Plan Builder. Nhiệm vụ duy nhất của bạn là tạo một lịch tập mới từ form chọn mục của người dùng, không trò chuyện vòng vo và không yêu cầu xác nhận thêm.

Quy tắc bắt buộc:
- Luôn tạo lịch tập mới, không chỉnh sửa lịch cũ.
- Response phải mở đầu bằng tên lịch, mô tả ngắn, các giả định AI đã tự quyết nếu form có "AI Decide", sau đó liệt kê từng buổi tập rõ ràng.
- Mảng suggestions phải chứa đủ hành động để lưu lịch trực tiếp: create_plan trước, tiếp theo create_session cho từng ngày, sau đó add_exercise cho từng bài.
- Dùng PlanId "{planId}" cho mọi action sau create_plan.
- Dùng SessionId dạng "{sessionId_Monday}", "{sessionId_Tuesday}",... và map đúng với dayOfWeek.
- dayOfWeek phải là tiếng Anh: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday.
- Chỉ chọn exerciseId có thật trong danh sách bài tập hệ thống.
- Không chẩn đoán y tế. Nếu có vấn đề sức khỏe, chọn bài an toàn hơn, giảm volume/intensity và ghi chú nên hỏi chuyên gia y tế khi đau nặng hoặc kéo dài.
- Ưu tiên Upper/Lower cho 4 buổi, Full Body hoặc Upper/Lower biến thể cho 3 buổi, Upper/Lower/Push/Pull/Legs hoặc PPL cho 5 buổi.
- Mỗi buổi nên có 4-7 bài. Mỗi bài phải có sets, reps và notes hữu ích.
- planName phải cụ thể, không dùng tên chung chung như "Workout Plan", "AI Workout Plan", "Lịch tập".
"""
            },
            new
            {
                role = "user",
                content =
$"""
Tạo lịch tập mới theo dữ liệu sau.

CUSTOMER_PROFILE:
{customerJson}

FORM_SELECTIONS:
{builderInputJson}

VALID_EXERCISES:
{exerciseJson}
"""
            }
        };

        var requestBody = new
        {
            model = "gpt-4o-mini",
            messages,
            temperature = 0.55,
            response_format = new
            {
                type = "json_schema",
                json_schema = new
                {
                    name = "workout_plan_builder_response",
                    strict = true,
                    schema = new
                    {
                        type = "object",
                        properties = new
                        {
                            response = new { type = "string", description = "Nội dung lịch tập hiển thị cho user." },
                            suggestions = new
                            {
                                type = "array",
                                items = new
                                {
                                    type = "object",
                                    properties = new
                                    {
                                        action = new { type = "string", description = "create_plan, create_session hoặc add_exercise." },
                                        planId = new { type = "string", description = "Luôn dùng {planId} khi tạo lịch mới." },
                                        sessionId = new { type = "string", description = "Placeholder {sessionId_Day} hoặc rỗng cho create_plan." },
                                        exerciseId = new { type = "string", description = "Mã ID thật của bài tập trong hệ thống." },
                                        planName = new { type = "string", description = "Tên lịch tập." },
                                        goal = new { type = "string", description = "Mục tiêu tập." },
                                        planDescription = new { type = "string", description = "Mô tả lịch tập." },
                                        daysPerWeek = new { type = "integer", description = "Số ngày tập mỗi tuần." },
                                        dayOfWeek = new { type = "string", description = "Thứ trong tuần bằng tiếng Anh." },
                                        focus = new { type = "string", description = "Trọng tâm buổi tập." },
                                        sets = new { type = "integer", description = "Số sets." },
                                        reps = new { type = "string", description = "Số reps." },
                                        notes = new { type = "string", description = "Ghi chú kỹ thuật/an toàn." }
                                    },
                                    required = new[] { "action", "planId", "sessionId", "exerciseId", "planName", "goal", "planDescription", "daysPerWeek", "dayOfWeek", "focus", "sets", "reps", "notes" },
                                    additionalProperties = false
                                }
                            }
                        },
                        required = new[] { "response", "suggestions" },
                        additionalProperties = false
                    }
                }
            }
        };

        var json = JsonSerializer.Serialize(requestBody);
        var response = await _httpClient.PostAsync(
            "https://api.openai.com/v1/chat/completions",
            new StringContent(json, Encoding.UTF8, "application/json"));

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            throw new Exception($"OpenAI Error: {error}");
        }

        var result = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(result);
        var aiContent = document.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(aiContent))
        {
            return new ChatResponseDto
            {
                Response = "AI không trả về dữ liệu.",
                Suggestions = new List<AISuggestionDto>()
            };
        }

        var aiResult = JsonSerializer.Deserialize<ChatResponseDto>(
            aiContent,
            new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                PropertyNameCaseInsensitive = true
            });

        if (aiResult?.Suggestions != null)
        {
            aiResult.Suggestions = aiResult.Suggestions
                .Where(x => !string.IsNullOrWhiteSpace(x.Action))
                .ToList();
        }

        return aiResult ?? new ChatResponseDto
        {
            Response = "Không nhận được phản hồi.",
            Suggestions = new List<AISuggestionDto>()
        };
    }

    public async Task<ChatResponseDto> ChatAsync(string userId, string message)
    {
        // ==========================
        // Chat History
        // ==========================
        var history = await _chatRepository.GetRecentMessagesAsync(userId, 20);
        history.Reverse();

        var apiKey = _configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new Exception("OpenAI API key is missing.");
        }

        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        // ==========================
        // Customer Profile
        // ==========================
        var customer = await _customerRepository.GetByUserIdAsync(userId);
        var user = await _userRepository.GetByIdAsync(userId);

        var customerJson = customer == null
            ? "null (người dùng chưa tạo hồ sơ; vẫn trò chuyện bình thường và chỉ hỏi thêm thông tin khi thực sự cần cá nhân hóa)"
            : JsonSerializer.Serialize(
                new
                {
                    customer.Id,
                    customer.UserId,
                    FullName = user?.FullName ?? "",
                    Email = user?.Email ?? "",
                    customer.Gender,
                    customer.Age,
                    customer.Bmi,
                    customer.HeightCm,
                    customer.WeightKg,
                    customer.Goal,
                    customer.ExperienceLevel,
                    customer.InjuryNotes
                },
                new JsonSerializerOptions { WriteIndented = true });
        // ==========================
        // Workout Plans (trimmed to reduce token usage)
        // ==========================
        var plans = await _workoutRepository.GetByUserIdAsync(userId);
        var activePlan = plans.FirstOrDefault(p => p.IsActive);

        var workoutJson = activePlan == null ? "null" : JsonSerializer.Serialize(
            new
            {
                id = activePlan.Id,
                name = activePlan.Name,
                goal = activePlan.Goal,
                daysPerWeek = activePlan.DaysPerWeek,
                sessions = activePlan.Sessions.Select(s => new
                {
                    id = s.Id,
                    dayOfWeek = s.DayOfWeek,
                    focus = s.Focus,
                    exercises = s.Exercises.Select(ex => new
                    {
                        exerciseId = ex.ExerciseId,
                        exerciseName = ex.ExerciseName,
                        sets = ex.Sets,
                        reps = ex.Reps
                    })
                })
            },
            new JsonSerializerOptions { WriteIndented = false });

        // ==========================
        // Exercises (trimmed to reduce token usage)
        // ==========================
        var exercises = (await _exerciseRepository.GetAllAsync()).ToList();
        var exerciseJson = JsonSerializer.Serialize(
            exercises.Select(e => new
            {
                id = e.Id,
                name = e.Name,
                equipment = e.Equipment,
                difficulty = e.Difficulty
            }),
            new JsonSerializerOptions { WriteIndented = false });

        // ==========================
        // Build Messages với SYSTEM PROMPT LUẬT THÉP
        // ==========================
        var messages = new List<object>();

        messages.Add(new
        {
            role = "system",
            content =
$$"""
Bạn là GymSupport AI Coach: một người bạn đồng hành am hiểu fitness, ấm áp, vui vẻ và nói chuyện tự nhiên. Bạn vừa có thể tư vấn tập luyện, dinh dưỡng, phục hồi và quản lý lịch tập, vừa có thể chào hỏi, tán gẫu và trò chuyện đời thường với người dùng.

=========================================
PHONG CÁCH TRÒ CHUYỆN:
- Trả lời thân thiện, thoải mái, có cảm xúc và linh hoạt như một người bạn đồng hành đáng tin cậy; không nói như biểu mẫu hay tổng đài.
- Có thể chào hỏi, pha chút hài hước phù hợp, động viên, hỏi thăm và tán gẫu tự nhiên. Hãy bắt nhịp cách xưng hô, độ dài và năng lượng của người dùng.
- Không ép mọi cuộc trò chuyện quay về gym. Với câu hỏi đời thường, hãy trả lời hữu ích trong khả năng của mình; nếu không chắc, nói rõ thay vì bịa.
- Khi người dùng chỉ trò chuyện, hỏi kiến thức hoặc xin gợi ý, luôn trả `suggestions: []`; tuyệt đối không tác động database.
- Chỉ sinh `suggestions` khi người dùng xác nhận rõ ràng rằng họ muốn lưu/áp dụng thay đổi lịch tập vào hệ thống. Việc lưu sẽ được hệ thống kiểm tra quyền Premium riêng.
- Không chẩn đoán bệnh hoặc thay thế bác sĩ. Khi có dấu hiệu nguy hiểm, đau nặng hay kéo dài, khuyên người dùng gặp chuyên gia y tế.

=========================================
KIẾN TRÚC DỮ LIỆU CỦA HỆ THỐNG:
1. WorkoutPlan (Lịch tập tổng)
2. WorkoutSession (Buổi tập theo thứ: "Monday", "Tuesday",...)
3. ExerciseInSession (Bài tập chi tiết nằm trong từng Session)
=========================================
HÀNH ĐỘNG 1: THÊM BÀI TẬP MỚI (ADD EXERCISE)
1. KIỂM TRA THỨ/BUỔI TẬP: Khi người dùng nói muốn thêm một bài tập (Ví dụ: "Thêm cho anh bài Bench Press"), bạn PHẢI QUÉT trong lời thoại xem họ đã chỉ định cụ thể là thêm vào thứ mấy chưa.
   --> NẾU CHƯA NÓI THỨ: Tuyệt đối KHÔNG ĐƯỢC tự ý sinh hành động 'add_exercise'. Bạn phải chat text để hỏi lại: "Dạ, anh/chị muốn thêm bài [Tên bài] vào buổi tập của thứ mấy trong tuần ạ (Ví dụ: Thứ 2, Thứ 4...)?"
   --> NẾU ĐÃ CÓ THỨ CỤ THỂ: Chuyển sang bước 2.
2. KIỂM TRA THÔNG SỐ (SETS/REPS): 
   --> Nếu người dùng có mô tả số sets, reps cụ thể (Ví dụ: "Thêm bài Bench Press vào Thứ 2 tập 4 hiệp 12 reps"): Bạn PHẢI tuân thủ điền chính xác số `sets: 4` và `reps: "12"` vào json hành động.
   --> Nếu người dùng KHÔNG nói thông số (Ví dụ: "Thêm bài Bench Press vào Thứ 2"): Bạn hãy tự động điền thông số tiêu chuẩn mặc định là `sets: 4` và `reps: "10-12"` thay vì để trống.

-----------------------------------------
HÀNH ĐỘNG 2: XÓA BÀI TẬP (REMOVE EXERCISE)
Khi người dùng yêu cầu xóa một bài tập (Ví dụ: "Xóa bài Bench Press giúp anh"):
1. Trường hợp bài tập đó CHỈ XUẤT HIỆN DUY NHẤT ở 1 buổi trong toàn bộ Plan: Sinh ngay hành động 'remove_exercise' để xóa bài đó tại buổi đó.
2. Trường hợp bài tập đó XUẤT HIỆN TRÙNG LẶP ở từ 2 buổi trở lên trong Plan (Ví dụ: Bench Press xuất hiện ở cả buổi Thứ 2 và Thứ 6):
   --> TUYỆT ĐỐI KHÔNG ĐƯỢC tự ý chọn một buổi để xóa, cũng KHÔNG ĐƯỢC tự ý xóa hết. Mảng `suggestions` bắt buộc phải để rỗng `[]`.
   --> Bạn phải đưa câu hỏi xác nhận rõ ràng ở trường `response`: "Dạ, em thấy bài [Tên bài] đang có mặt ở cả lịch tập [Thứ A] và [Thứ B]. Anh/Chị muốn xóa bài này ở riêng một buổi cụ thể nào hay muốn xóa hoàn toàn khỏi tất cả các buổi ạ?"
   --> CHỈ KHI NÀO người dùng phản hồi rõ ràng (Ví dụ: "Xóa ở Thứ 2 thôi" hoặc "Xóa hết đi em") thì ở lượt chat kế tiếp bạn mới được sinh hành động 'remove_exercise' tương ứng với lựa chọn của họ.
=========================================
QUY TẮC ĐỒNG BỘ NGÔN NGỮ NGÀY THÁNG (BẮT BUỘC):
- Dữ liệu hệ thống lưu tên thứ bằng tiếng Anh: "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday".
- Khi người dùng nói "Thứ 2", bạn phải tự hiểu là "Monday"; "Thứ 4" là "Wednesday"; "Thứ 6" là "Friday",... để tra cứu chính xác trong trường `DayOfWeek` của dữ liệu {{workoutJson}}.
============================================
Khi AI gợi ý hoặc tạo lịch tập cho người dùng trong app GymSupport, hãy ưu tiên thiết kế lịch theo phương pháp Upper/Lower Split.

Yêu cầu chính:

Nếu người dùng tập 4 buổi/tuần: ưu tiên lịch Upper - Lower - nghỉ - Upper - Lower.
Nếu người dùng tập 3 buổi/tuần: có thể dùng biến thể Upper - Lower - Full Body hoặc Upper - Lower - Upper/Lower luân phiên theo tuần.
Nếu người dùng tập 5 buổi/tuần: ưu tiên Upper - Lower - Push - Pull - Legs hoặc Upper - Lower - Upper - Lower - Weak Point.
Nếu người dùng mới tập: giảm volume, chọn bài dễ kiểm soát kỹ thuật.
Nếu người dùng trung cấp/nâng cao: tăng volume, thêm bài compound và isolation hợp lý.

Nguyên tắc tạo lịch:

Ưu tiên cân bằng nhóm cơ thân trên và thân dưới.
Không xếp hai buổi nặng cùng nhóm cơ liên tiếp.
Mỗi buổi nên có 4–7 bài tập.
Mỗi bài nên có số sets, reps, rest time và ghi chú kỹ thuật.
Ưu tiên bài compound trước, bài isolation sau.
Luôn có khởi động trước buổi tập và giãn cơ sau buổi tập.
Lịch phải phù hợp với mục tiêu của người dùng: tăng cơ, giảm mỡ, tăng sức mạnh hoặc duy trì sức khỏe.
Lịch phải phù hợp với số buổi/tuần, kinh nghiệm tập, thiết bị hiện có, chấn thương hoặc hạn chế vận động nếu có.
Nếu thiếu thông tin, hãy tự đưa ra giả định hợp lý và ghi rõ giả định đó.

Quy tắc đặt tên và nội dung phụ cho lịch AI:
- `planName` khi tạo lịch mới phải là tên cụ thể, ngắn gọn, chuyên nghiệp, có mục tiêu/số buổi/kiểu split. Không dùng tên chung chung như "Workout Plan", "AI Workout Plan", "Lịch tập".
  Ví dụ tốt: "Tăng cơ Upper/Lower 4 buổi", "Giảm mỡ Full Body 3 buổi", "Strength Push Pull Legs 5 buổi".
- `planDescription` phải tóm tắt 1-2 câu: lịch dành cho ai, mục tiêu chính, cách phân bổ buổi tập và lưu ý phục hồi/an toàn.
- `focus` của mỗi session phải rõ nhóm cơ/ý đồ buổi tập, ví dụ "Upper Body - Ngực/Lưng/Vai", "Lower Body - Đùi/Mông/Core".
- `notes` của mỗi bài phải hữu ích: cue kỹ thuật, mức RPE hoặc lưu ý an toàn ngắn. Không để notes trống khi tạo lịch.
- Trong response văn bản, luôn mở đầu bằng tên lịch được đề xuất, mô tả ngắn, giả định nếu có, rồi mới liệt kê từng ngày.

Format output:

Trả về lịch tập theo từng ngày.
Mỗi ngày gồm: tên buổi, nhóm cơ chính, danh sách bài tập, sets, reps, thời gian nghỉ, ghi chú.
Có thêm lời khuyên ngắn về dinh dưỡng, phục hồi và tăng tiến mức tạ.

Ví dụ logic ưu tiên:
Nếu user chọn 4 buổi/tuần:
Day 1: Upper Body
Day 2: Lower Body
Day 3: Rest / Cardio nhẹ
Day 4: Upper Body
Day 5: Lower Body
Day 6: Rest hoặc Mobility
Day 7: Rest

Hãy luôn ưu tiên Upper/Lower Split trước các kiểu lịch khác, trừ khi mục tiêu, số buổi tập hoặc tình trạng sức khỏe của người dùng khiến lịch khác phù hợp hơn.
=========================================
DỮ LIỆU THỰC TẾ HIỆN TẠI TỪ DATABASE CẤP CHO BẠN:
- THÔNG TIN CUSTOMER PROFILE CỦA USER: {{customerJson}}
- WORKOUT PLAN ĐANG KÍCH HOẠT CỦA USER: {{workoutJson}}
- DANH SÁCH BÀI TẬP HỢP LỆ TRONG HỆ THỐNG: {{exerciseJson}}

=========================================

QUY TẮC CÁ NHÂN HÓA THEO CUSTOMER PROFILE:
- Bạn phải đọc thông tin customer profile để cá nhân hóa câu trả lời.
- Nếu customer profile là null, vẫn trò chuyện và đưa gợi ý chung bình thường; chỉ hỏi thêm tuổi, mục tiêu, kinh nghiệm hoặc chấn thương khi thông tin đó cần thiết cho một lời khuyên cụ thể.
- Dựa vào gender, age, heightCm, weightKg, bmi, goal, experienceLevel, injuryNotes để tư vấn.
- Nếu injuryNotes có dữ liệu, phải ưu tiên cảnh báo an toàn và tránh bài tập có thể làm nặng chấn thương.
- Nếu goal là tăng cơ, ưu tiên lời khuyên về progressive overload, protein, phục hồi và lịch tập phù hợp.
- Nếu goal là giảm mỡ, ưu tiên lời khuyên về calo, cardio, tập kháng lực và duy trì cơ.
- Không chẩn đoán y tế. Nếu người dùng đau nặng, đau kéo dài hoặc có dấu hiệu bất thường, khuyên họ gặp bác sĩ/chuyên gia y tế.
LUỒNG TƯ VẤN VÀ QUY TẮC SINH HÀNH ĐỘNG (QUAN TRỌNG NHẤT):
=========================================
TRƯỜNG HỢP 1: TRONG DỮ LIỆU "WORKOUT PLAN ĐANG KÍCH HOẠT" ĐANG TRỐNG RỖNG (HOẶC BẰNG NULL)
- GIAI ĐOẠN THẢO LUẬN: Khi user yêu cầu lên lịch tập mới, gợi ý giáo án, hoặc yêu cầu "lên danh sách bài tập cụ thể cho từng ngày"... Bạn CHỈ ĐƯỢC PHÉP liệt kê và phân tích chi tiết giáo án bằng văn bản thuần (text) ở trường `response`.
  --> TUYỆT ĐỐI KHÔNG ĐƯỢC sinh bất kỳ hành động nào vào mảng `suggestions`. Mảng `suggestions` lúc này bắt buộc phải để rỗng `[]`.
  --> Ở cuối câu `response`, bạn luôn luôn phải hỏi câu xác nhận rõ ràng phù hợp với đại từ xưng hô đang trò chuyện (Ví dụ: "Anh/Chị có đồng ý khởi tạo và lưu lịch tập tuần này lên hệ thống không?").

- GIAI ĐOẠN XÁC NHẬN: CHỈ KHI NÀO user đọc xong văn bản đề xuất bài tập của bạn và phản hồi bằng các từ khóa chốt hạ (Ví dụ: "Ok lưu đi", "Đồng ý", "Tạo lịch đi em", "Áp dụng đi", "Lưu lịch này nhé") -> Lúc này, dựa vào lịch sử chat cũ để gom lại thông tin bài tập đã thảo luận, bạn mới được phép đổ đồng thời 'create_plan', 'create_session', và 'add_exercise' vào mảng `suggestions`.
  --> Quy tắc map ID giả định: Dùng "{planId}" và "{sessionId_Monday}", "{sessionId_Tuesday}",... cho các hành động đi kèm nhau trong mảng.

TRƯỜNG HỢP 2: TRONG DỮ LIỆU "WORKOUT PLAN ĐANG KÍCH HOẠT" ĐÃ CÓ SẴN DỮ LIỆU
- Khi user yêu cầu chỉnh sửa (tăng/giảm sets, reps, thay đổi ghi chú) hoặc xóa bài tập, giảm bớt bài tập:
  --> Tuyệt đối KHÔNG ĐƯỢC sinh lại hành động 'create_plan' hay 'create_session'.
  --> Nếu user muốn SỬA thông số (sets/reps): Sinh hành động 'update_exercise'.
  --> Nếu user muốn XÓA/GIẢM BỚT bài tập (ví dụ: yêu cầu xóa bài Bench Press): Sinh hành động 'remove_exercise'.
  --> Bạn phải đối chiếu chính xác tên bài tập user muốn xóa với `ExerciseName` trong {{workoutJson}} để tìm ra đúng `ExerciseId` thực tế, kèm theo `Id` của Plan và `Id` của Session chứa bài đó để điền vào hành động.

=========================================
QUY TẮC PHẢN HỒI RESPONSE VĂN BẢN KHÔNG HARDCODE:
- Bạn hãy viết câu thoại `response` phản hồi cực kỳ tự nhiên, tinh tế, tự động xưng hô phù hợp giới tính/tuổi tác theo ngữ cảnh cũ.
- Nội dung câu thoại phải ăn khớp chính xác với hành động thực tế (Ví dụ: Nếu người dùng chốt lưu lịch mới, hãy chúc mừng họ. Nếu người dùng bảo thêm/xóa bài lẻ, hãy thông báo cụ thể đã thêm/xóa bài đó thành công).
=========================================
1. Người dùng yêu cầu Thêm/Sửa/Xóa một bài tập nhưng TÊN BÀI TẬP ĐÓ KHÔNG TỒN TẠI trong danh sách {{exerciseJson}} hoặc viết sai chính tả quá nặng không thể nhận diện: Bạn phải phản hồi lịch sự rằng hệ thống chưa hỗ trợ bài tập này và gợi ý họ chọn một bài tương tự có trong danh sách hệ thống.
2. Người dùng yêu cầu thêm bài tập vào một Thứ (Ví dụ: Thứ 5) nhưng trong lịch tập hiện tại {{workoutJson}} CHƯA CÓ buổi tập (Session) nào cho Thứ 5:
   --> Bạn phải phải hỏi người dùng xác nhận trước khi tự động sinh ĐỒNG THỜI 2 hành động liên tiếp trong mảng `suggestions`: Đầu tiên là 'create_session' cho ngày Thứ 5 đó, sau đó liền kề là 'add_exercise' để nạp bài tập vào chính Session vừa tạo.
=========================================
QUY TẮC CẤU TRÚC JSON CHO TỪNG HÀNH ĐỘNG (BẮT BUỘC TUÂN THỦ):
- Hành động tạo Plan: Thừa các trường khác thì đặt giá trị mặc định là chuỗi rỗng "" hoặc 0.
- Thứ tự sắp xếp mảng `suggestions` (nếu có): 'create_plan' -> 'create_session' -> 'add_exercise'.
"""
        });

        foreach (var item in history)
        {
            messages.Add(new { role = item.Role, content = item.Content });
        }

        messages.Add(new { role = "user", content = message });

        // =========================================================================
        // OpenAI Request sử dụng STRUCTURED OUTPUTS (json_schema nghiêm ngặt)
        // =========================================================================
        var requestBody = new
        {
            model = "gpt-4o-mini",
            messages,
            temperature = 0.7,
            response_format = new
            {
                type = "json_schema",
                json_schema = new
                {
                    name = "workout_chat_response",
                    strict = true,
                    schema = new
                    {
                        type = "object",
                        properties = new
                        {
                            response = new { type = "string", description = "Lời thoại phản hồi gửi tới user." },
                            suggestions = new
                            {
                                type = "array",
                                items = new
                                {
                                    type = "object",
                                    properties = new
                                    {
                                        action = new { type = "string", description = "Tên hành động tác động DB." },
                                        planId = new { type = "string", description = "Mã ID thật của Plan lấy từ database hoặc {planId}." },
                                        sessionId = new { type = "string", description = "Mã ID thật của Session lấy từ database hoặc dạng {sessionId_Day}." },
                                        exerciseId = new { type = "string", description = "Mã ID thật của bài tập lấy từ database." },
                                        planName = new { type = "string", description = "Tên lịch tập khi tạo mới." },
                                        goal = new { type = "string", description = "Mục tiêu tập khi tạo mới." },
                                        planDescription = new { type = "string", description = "Mô tả ngắn của lịch tập khi tạo mới." },
                                        daysPerWeek = new { type = "integer", description = "Số ngày tập một tuần." },
                                        dayOfWeek = new { type = "string", description = "Thứ trong tuần dạng tiếng Anh (ví dụ: Monday)." },
                                        focus = new { type = "string", description = "Nhóm cơ tiêu điểm của buổi tập." },
                                        sets = new { type = "integer", description = "Số sets tập." },
                                        reps = new { type = "string", description = "Số reps tập." },
                                        notes = new { type = "string", description = "Ghi chú thêm." }
                                    },
                                    required = new[] { "action", "planId", "sessionId", "exerciseId", "planName", "goal", "planDescription", "daysPerWeek", "dayOfWeek", "focus", "sets", "reps", "notes" },
                                    additionalProperties = false
                                }
                            }
                        },
                        required = new[] { "response", "suggestions" },
                        additionalProperties = false
                    }
                }
            }
        };

        var json = JsonSerializer.Serialize(requestBody);
        var response = await _httpClient.PostAsync(
            "https://api.openai.com/v1/chat/completions",
            new StringContent(json, Encoding.UTF8, "application/json"));

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            throw new Exception($"OpenAI Error: {error}");
        }

        var result = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(result);
        var aiContent = document.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(aiContent))
        {
            return new ChatResponseDto { Response = "AI không trả về dữ liệu." };
        }

        ChatResponseDto? aiResult;
        try
        {
            // Do Structured Outputs trả về chính xác camelCase, ta sử dụng JsonNamingPolicy.CamelCase để đồng bộ hóa hoàn hảo với C# PascalCase DTO
            aiResult = JsonSerializer.Deserialize<ChatResponseDto>(
                aiContent,
                new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                    PropertyNameCaseInsensitive = true
                });
        }
        catch
        {
            aiResult = new ChatResponseDto
            {
                Response = aiContent,
                Suggestions = new List<AISuggestionDto>()
            };
        }

        // Chat chỉ tư vấn và trả về suggestions. Việc ghi database được tách
        // sang POST /api/ai/apply để endpoint đó kiểm tra quyền Premium.
        if (aiResult?.Suggestions != null)
        {
            aiResult.Suggestions = aiResult.Suggestions
                .Where(x => !string.IsNullOrWhiteSpace(x.Action))
                .ToList();
        }

        // ==========================
        // Save History
        // ==========================
        await _chatRepository.CreateAsync(new ChatMessage { UserId = userId, Role = "user", Content = message });
        await _chatRepository.CreateAsync(new ChatMessage { UserId = userId, Role = "assistant", Content = aiResult?.Response ?? "" });

        return aiResult ?? new ChatResponseDto { Response = "Không nhận được phản hồi." };
    }

    public async Task<ImageAnalyzeResponseDto> AnalyzeImageAsync(
    Stream imageStream,
    string contentType,
    string mode)
    {
        var apiKey = _configuration["OpenAI:ApiKey"];

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new Exception("OpenAI API key is missing.");
        }

        _httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);

        using var memoryStream = new MemoryStream();
        await imageStream.CopyToAsync(memoryStream);

        var imageBytes = memoryStream.ToArray();
        var base64Image = Convert.ToBase64String(imageBytes);

        var imageDataUrl = $"data:{contentType};base64,{base64Image}";

        var prompt = mode switch
        {
            "equipment_info" => """
Bạn là huấn luyện viên gym. Hãy xem ảnh này và phân tích máy tập hoặc dụng cụ tập luyện.

Yêu cầu:
1. Nhận diện đây có thể là máy tập/dụng cụ gì.
2. Máy này dùng để tập nhóm cơ nào.
3. Gợi ý các bài tập có thể tập với máy/dụng cụ này.
4. Hướng dẫn cách dùng cơ bản.
5. Đưa ra lưu ý an toàn.

Nếu ảnh không rõ hoặc không chắc chắn, hãy nói rõ là không chắc.
Không bịa thông tin.

Trả về JSON đúng schema.
""",

            "form_check" => """
Bạn là huấn luyện viên gym. Hãy xem ảnh này để đánh giá form/tư thế tập luyện.

Yêu cầu:
1. Dự đoán người dùng đang tập bài gì.
2. Nhận xét form đang đúng ở điểm nào.
3. Nhận xét form có thể sai hoặc nguy hiểm ở điểm nào.
4. Gợi ý cách sửa form.
5. Đưa ra lưu ý an toàn.

Không chẩn đoán y tế.
Nếu ảnh không rõ, hãy nói ảnh chưa đủ rõ.
Không đưa ra kết luận tuyệt đối.

Trả về JSON đúng schema.
""",

            "body_check" => """
Bạn là huấn luyện viên gym. Hãy xem ảnh cơ thể người dùng và đưa ra đánh giá thể hình mang tính tham khảo.

Yêu cầu:
1. Nhận xét tổng quan vóc dáng dựa trên ảnh, nói lịch sự và không body-shaming.
2. Không ước lượng chính xác  bệnh lý hoặc chẩn đoán y tế.
3. Cho biết nhóm cơ nào có thể nên ưu tiên cải thiện.
4. Gợi ý bài tập phù hợp cho các nhóm cơ đó.
5. Gợi ý hướng tập luyện tổng quát: tăng cơ, siết cơ, cải thiện tư thế hoặc cân bằng cơ thể.
6. Đưa ra lưu ý an toàn.
7. Phần trăm mỡ, cân nặng, chiều cao chỉ nên ước lượng rất rộng nếu có thể, và phải nói rõ là ước lượng không chính xác.

Ví dụ nhóm cơ có thể gợi ý (muscles) đưa ra 4 cái thôi:
Cơ vai  (Deltoids):
Vai trước (Anterior Deltoid)
Vai giữa (Lateral Deltoid)
Vai sau (Posterior Deltoid)
Cơ chóp xoay(Rotator Cuff)

Tay (Arms):
Tay trước (Biceps):
Biceps Brachii (Cơ nhị đầu)
Brachialis (Cơ cánh tay)

Tay sau (Triceps Brachii)
Đầu dài (Long head)
Đầu ngoài (Lateral head)
Đầu giữa (Medial head)

Cẳng tay (Forearms):
Cơ ngửa/gập (Flexors)
Cơ sấp/duỗi (Extensors & Brachioradialis)

Cơ Lưng (Back):
Lưng xô (Latissimus Dorsi - Lats)
Cầu vai (Trapezius - Traps)
Lưng giữa (Rhomboids)
Tròn lớn (Teres Major)
Dựng cột sống (Erector Spinae)


Cơ Ngực (Chest)
Ngực trên (Clavicular head)
Ngực giữa(Sternal head)
Ngực dưới(Abdominal head)
Ngực nhỏ(Minor)

Chân (Legs & Glutes)
Đùi trước (Quadriceps):
Đùi sau(Hamstrings):

Cơ mông (Glutes)
Cơ mông lớn(Gluteus Maximus)
Cơ mông nhỡ(Gluteus Medius)
Cơ mông nhỏ(Gluteus Minimus)

Cơ khép đùi (Adductors)

Cơ bắp chân (Calves)


Cơ Bụng (Abs & Core)
Cơ thẳng bụng(Rectus Abdominis)
Cơ liên sườn ngoài(External Obliques)
Cơ liên sườn trong(Internal Obliques)
Cơ bụng ngang(Transversus Abdominis)

Nếu ảnh không rõ, che quá nhiều, hoặc góc chụp không đủ, hãy nói cần ảnh rõ hơn.
Trả về JSON đúng schema.
""",

            _ => """
Bạn là huấn luyện viên gym. Hãy phân tích ảnh và đưa ra lời khuyên tập luyện an toàn.
Trả về JSON đúng schema.
"""
        };

        var requestBody = new
        {
            model = "gpt-4.1-mini",
            messages = new object[]
            {
            new
            {
                role = "user",
                content = new object[]
                {
                    new
                    {
                        type = "text",
                        text = prompt
                    },
                    new
                    {
                        type = "image_url",
                        image_url = new
                        {
                            url = imageDataUrl
                        }
                    }
                }
            }
            },
            temperature = 0.2,
            response_format = new
            {
                type = "json_schema",
                json_schema = new
                {
                    name = "gym_image_analysis",
                    strict = true,
                    schema = new
                    {
                        type = "object",
                        properties = new
                        {
                            mode = new { type = "string" },
                            title = new { type = "string" },
                            summary = new { type = "string" },

                            detectedItems = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            bodyObservations = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            muscles = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            priorityMuscles = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            suggestedExercises = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            formFeedback = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            trainingAdvice = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            warnings = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            }
                        },
                        required = new[]
                        {
                        "mode",
                        "title",
                        "summary",
                        "detectedItems",
                        "bodyObservations",
                        "muscles",
                        "priorityMuscles",
                        "suggestedExercises",
                        "formFeedback",
                        "trainingAdvice",
                        "warnings"
                    },
                        additionalProperties = false
                    }
                }
            },
            max_tokens = 1000
        };

        var json = JsonSerializer.Serialize(requestBody);

        var response = await _httpClient.PostAsync(
            "https://api.openai.com/v1/chat/completions",
            new StringContent(json, Encoding.UTF8, "application/json"));

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            throw new Exception($"OpenAI Vision Error: {error}");
        }

        var result = await response.Content.ReadAsStringAsync();

        using var document = JsonDocument.Parse(result);

        var aiContent = document.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(aiContent))
        {
            return new ImageAnalyzeResponseDto
            {
                Mode = mode,
                Title = "Không phân tích được ảnh",
                Summary = "AI không trả về kết quả.",
                Warnings = new List<string>
            {
                "Vui lòng thử lại với ảnh rõ hơn."
            }
            };
        }

        var analysis = JsonSerializer.Deserialize<ImageAnalyzeResponseDto>(
            aiContent,
            new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                PropertyNameCaseInsensitive = true
            });

        return analysis ?? new ImageAnalyzeResponseDto
        {
            Mode = mode,
            Title = "Không phân tích được ảnh",
            Summary = aiContent
        };
    }
    public async Task<VideoFormAnalyzeResponseDto> AnalyzeFormVideoAsync(
    Stream videoStream,
    string fileName,
    string contentType)
    {
        var tempDir = Path.Combine(
            Path.GetTempPath(),
            "gymsupport_video_" + Guid.NewGuid());

        Directory.CreateDirectory(tempDir);

        try
        {
            var safeFileName = Path.GetFileName(fileName);
            var inputPath = Path.Combine(tempDir, safeFileName);

            await using (var fileStream = File.Create(inputPath))
            {
                await videoStream.CopyToAsync(fileStream);
            }

            var outputPattern = Path.Combine(tempDir, "frame_%03d.jpg");

            var args =
                $"-i \"{inputPath}\" -vf \"fps=2,scale=768:-1\" -frames:v 12 \"{outputPattern}\"";

            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "ffmpeg",
                    Arguments = args,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                }
            };

            process.Start();

            var ffmpegError = await process.StandardError.ReadToEndAsync();

            await process.WaitForExitAsync();

            if (process.ExitCode != 0)
            {
                throw new Exception($"FFmpeg error: {ffmpegError}");
            }

            var frameFiles = Directory.GetFiles(tempDir, "frame_*.jpg")
                .OrderBy(x => x)
                .Take(12)
                .ToList();

            if (!frameFiles.Any())
            {
                throw new Exception("Không thể trích xuất frame từ video.");
            }

            return await AnalyzeFramesWithOpenAIAsync(frameFiles);
        }
        finally
        {
            if (Directory.Exists(tempDir))
            {
                Directory.Delete(tempDir, true);
            }
        }
    }
    private async Task<VideoFormAnalyzeResponseDto> AnalyzeFramesWithOpenAIAsync(
    List<string> frameFiles)
    {
        var apiKey = _configuration["OpenAI:ApiKey"];

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new Exception("OpenAI API key is missing.");
        }

        _httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", apiKey);

        var prompt = """
Bạn là AI Form Auditor trong app GymSupport. Bạn đang phân tích video tập gym đã được tách thành các frame theo thứ tự thời gian.

BẠN KHÔNG ĐƯỢC BIẾT TRƯỚC BÀI TẬP.
Bạn phải tự nhận diện bài tập từ video nếu có thể.

NHIỆM VỤ CHÍNH:
1. Tự nhận diện bài tập trong video.
2. Nếu không chắc bài tập là gì, detectedExercise phải ghi "Không chắc chắn".
3. Nếu không chắc bài tập là gì, confidence = "low".
4. Sau khi nhận diện bài tập, kiểm tra form có ĐẠT hay KHÔNG ĐẠT.
5. Không được khen chung chung nếu có lỗi rõ ràng.

QUY TẮC BẮT BUỘC:
1. Ưu tiên tìm lỗi form trước, sau đó mới nói điểm đúng.
2. Nếu thấy lỗi nguy hiểm, riskLevel = "high".
3. Nếu lỗi form có thể gây chấn thương, isFormAcceptable = false.
4. Nếu video không đủ rõ, confidence = "low" và isFormAcceptable = false.
5. Nếu không thấy đủ chuyển động để xác định bài tập, confidence = "low" và isFormAcceptable = false.
6. Không chẩn đoán y tế.
7. Không nói "form tốt" nếu vẫn có lỗi lớn.
8. Không được viết quá tích cực nếu video thể hiện form sai.
9. Chỉ nhận xét dựa trên những gì thấy được trong frame.
10. Trả lời bằng tiếng Việt.
11. Nếu không nhìn rõ toàn bộ động tác, không được pass form.
12. Nếu có majorIssues thì isFormAcceptable bắt buộc là false.

TIÊU CHÍ ĐÁNH GIÁ CHUNG:
- Cột sống/lưng có giữ trung lập không?
- Vai có bị nhún hoặc cuộn về trước không?
- Core có được kiểm soát không?
- Có dùng đà quá nhiều không?
- Biên độ chuyển động có hợp lý không?
- Tốc độ động tác có kiểm soát không?
- Đường đi của khớp có an toàn không?
- Có dấu hiệu mất kiểm soát tạ/máy không?

CÁCH CHẤM:
- Nếu có từ 1 lỗi nguy hiểm trở lên: riskLevel = "high", isFormAcceptable = false.
- Nếu có nhiều lỗi kỹ thuật nhưng chưa quá nguy hiểm: riskLevel = "medium", isFormAcceptable = false.
- Nếu chỉ có lỗi nhỏ và video đủ rõ: riskLevel = "low", isFormAcceptable = true.
- Nếu không đủ rõ để đánh giá: confidence = "low", isFormAcceptable = false.
- Nếu không nhận diện chắc bài tập: confidence = "low", isFormAcceptable = false.

YÊU CẦU OUTPUT:
- targetExercise = "auto_detect".
- detectedExercise = bài tập bạn quan sát được, hoặc "Không chắc chắn".
- overallVerdict phải nói rõ: "Form chưa đạt", "Form tạm ổn", hoặc "Form tốt".
- Nếu isFormAcceptable = false thì overallVerdict không được là "Form tốt".
- majorIssues phải liệt kê lỗi lớn nếu có.
- minorIssues liệt kê lỗi nhỏ nếu có.
- correctPoints chỉ liệt kê điểm đúng thật sự quan sát được.
- correctiveCues phải là câu hướng dẫn sửa ngắn gọn, dễ làm.
- warnings phải nhắc kết quả chỉ mang tính tham khảo.

Trả về JSON đúng schema.
""";

        var content = new List<object>
    {
        new
        {
            type = "text",
            text = prompt
        }
    };

        foreach (var framePath in frameFiles)
        {
            var bytes = await File.ReadAllBytesAsync(framePath);
            var base64 = Convert.ToBase64String(bytes);

            content.Add(new
            {
                type = "image_url",
                image_url = new
                {
                    url = $"data:image/jpeg;base64,{base64}",
                    detail = "low"
                }
            });
        }

        var requestBody = new
        {
            model = "gpt-4.1-mini",
            messages = new object[]
            {
            new
            {
                role = "user",
                content
            }
            },
            temperature = 0.1,
            response_format = new
            {
                type = "json_schema",
                json_schema = new
                {
                    name = "video_form_check",
                    strict = true,
                    schema = new
                    {
                        type = "object",
                        properties = new
                        {
                            mode = new { type = "string" },
                            title = new { type = "string" },
                            summary = new { type = "string" },

                            targetExercise = new { type = "string" },
                            detectedExercise = new { type = "string" },

                            confidence = new { type = "string" },
                            isFormAcceptable = new { type = "boolean" },
                            riskLevel = new { type = "string" },
                            overallVerdict = new { type = "string" },

                            movementSummary = new { type = "string" },

                            majorIssues = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            minorIssues = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            correctPoints = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            frameObservations = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            correctiveCues = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            suggestedFixes = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            muscles = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            },

                            warnings = new
                            {
                                type = "array",
                                items = new { type = "string" }
                            }
                        },
                        required = new[]
                        {
                        "mode",
                        "title",
                        "summary",
                        "targetExercise",
                        "detectedExercise",
                        "confidence",
                        "isFormAcceptable",
                        "riskLevel",
                        "overallVerdict",
                        "movementSummary",
                        "majorIssues",
                        "minorIssues",
                        "correctPoints",
                        "frameObservations",
                        "correctiveCues",
                        "suggestedFixes",
                        "muscles",
                        "warnings"
                    },
                        additionalProperties = false
                    }
                }
            },
            max_tokens = 1600
        };

        var json = JsonSerializer.Serialize(requestBody);

        var response = await _httpClient.PostAsync(
            "https://api.openai.com/v1/chat/completions",
            new StringContent(json, Encoding.UTF8, "application/json"));

        if (!response.IsSuccessStatusCode)
        {
            var error = await response.Content.ReadAsStringAsync();
            throw new Exception($"OpenAI Video Form Check Error: {error}");
        }

        var result = await response.Content.ReadAsStringAsync();

        using var document = JsonDocument.Parse(result);

        var aiContent = document.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        if (string.IsNullOrWhiteSpace(aiContent))
        {
            return new VideoFormAnalyzeResponseDto
            {
                Mode = "video_form_check",
                Title = "Không phân tích được video",
                Summary = "AI không trả về kết quả.",
                TargetExercise = "auto_detect",
                DetectedExercise = "Không chắc chắn",
                Confidence = "low",
                IsFormAcceptable = false,
                RiskLevel = "medium",
                OverallVerdict = "Không đủ dữ liệu để đánh giá form.",
                Warnings = new List<string>
            {
                "Vui lòng thử lại với video rõ hơn.",
                "Kết quả chỉ mang tính tham khảo, không thay thế huấn luyện viên hoặc bác sĩ."
            }
            };
        }

        var analysis = JsonSerializer.Deserialize<VideoFormAnalyzeResponseDto>(
            aiContent,
            new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                PropertyNameCaseInsensitive = true
            });

        if (analysis == null)
        {
            return new VideoFormAnalyzeResponseDto
            {
                Mode = "video_form_check",
                Title = "Không phân tích được video",
                Summary = aiContent,
                TargetExercise = "auto_detect",
                DetectedExercise = "Không chắc chắn",
                Confidence = "low",
                IsFormAcceptable = false,
                RiskLevel = "medium",
                OverallVerdict = "Không đủ dữ liệu để đánh giá form.",
                Warnings = new List<string>
            {
                "Kết quả chỉ mang tính tham khảo."
            }
            };
        }

        analysis.Mode = "video_form_check";
        analysis.TargetExercise = "auto_detect";

        if (string.IsNullOrWhiteSpace(analysis.DetectedExercise))
        {
            analysis.DetectedExercise = "Không chắc chắn";
        }

        if (string.IsNullOrWhiteSpace(analysis.Confidence))
        {
            analysis.Confidence = "medium";
        }

        if (string.IsNullOrWhiteSpace(analysis.RiskLevel))
        {
            analysis.RiskLevel = "medium";
        }

        // Hậu kiểm để tránh AI trả quá tích cực
        if (analysis.MajorIssues.Any())
        {
            analysis.IsFormAcceptable = false;

            if (analysis.RiskLevel.Equals("low", StringComparison.OrdinalIgnoreCase))
            {
                analysis.RiskLevel = "medium";
            }

            if (string.IsNullOrWhiteSpace(analysis.OverallVerdict)
                || analysis.OverallVerdict.Contains("tốt", StringComparison.OrdinalIgnoreCase))
            {
                analysis.OverallVerdict = "Form chưa đạt, cần sửa các lỗi kỹ thuật chính.";
            }
        }

        if (analysis.Confidence.Equals("low", StringComparison.OrdinalIgnoreCase))
        {
            analysis.IsFormAcceptable = false;

            if (string.IsNullOrWhiteSpace(analysis.OverallVerdict)
                || analysis.OverallVerdict.Contains("tốt", StringComparison.OrdinalIgnoreCase))
            {
                analysis.OverallVerdict = "Chưa đủ dữ liệu rõ ràng để đánh giá form chính xác.";
            }
        }

        if (analysis.DetectedExercise.Contains("Không chắc", StringComparison.OrdinalIgnoreCase))
        {
            analysis.Confidence = "low";
            analysis.IsFormAcceptable = false;

            if (string.IsNullOrWhiteSpace(analysis.OverallVerdict)
                || analysis.OverallVerdict.Contains("tốt", StringComparison.OrdinalIgnoreCase))
            {
                analysis.OverallVerdict = "Chưa nhận diện chắc chắn bài tập nên không thể kết luận form tốt.";
            }
        }

        if (!analysis.Warnings.Any())
        {
            analysis.Warnings.Add("Kết quả chỉ mang tính tham khảo, không thay thế huấn luyện viên hoặc bác sĩ.");
        }

        return analysis;
    }

}
