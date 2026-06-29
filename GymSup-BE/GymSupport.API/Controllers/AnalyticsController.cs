using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/admin/analytics")]
[Authorize(Roles = "Admin,Manager")]
public class AnalyticsController : ControllerBase
{
    private readonly IAnalyticsService _analyticsService;

    public AnalyticsController(IAnalyticsService analyticsService)
    {
        _analyticsService = analyticsService;
    }

    /// <summary>
    /// Báo cáo mức độ hoạt động người dùng (DAU / WAU / MAU)
    /// </summary>
    /// <remarks>
    /// Activity được đo bằng số lần user bắt đầu buổi tập (WorkoutSessionLog.StartTime).
    /// - DAU: trung bình số user duy nhất mỗi ngày trong khoảng thời gian.
    /// - WAU: trung bình số user duy nhất mỗi tuần trong khoảng thời gian.
    /// - MAU: tổng số user duy nhất trong toàn bộ khoảng thời gian.
    /// - DailyBreakdown: chi tiết số user hoạt động từng ngày.
    /// </remarks>
    [HttpGet("active-users")]
    public async Task<IActionResult> GetActiveUsers(
        [FromQuery] DateTime from,
        [FromQuery] DateTime to)
    {
        try
        {
            if (from > to)
                return BadRequest(new { message = "from phải nhỏ hơn hoặc bằng to" });

            var result = await _analyticsService.GetActiveUsersAsync(from, to);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy dữ liệu active users", error = ex.Message });
        }
    }

    /// <summary>
    /// Báo cáo retention – tỉ lệ user quay lại sau khi đăng ký
    /// </summary>
    /// <remarks>
    /// Cohort = user đăng ký (VerifiedAt) trong khoảng [from, to].
    /// Retention được tính dựa trên việc user có bắt đầu ít nhất 1 buổi tập
    /// trong cửa sổ thời gian tương ứng (Day 1 / 7 / 30).
    /// Users chưa đủ thời gian chờ (e.g. mới đăng ký hôm nay) được loại khỏi
    /// mẫu eligible của Day7/Day30 để không làm sai số liệu.
    /// </remarks>
    [HttpGet("retention")]
    public async Task<IActionResult> GetRetention(
        [FromQuery] DateTime from,
        [FromQuery] DateTime to)
    {
        try
        {
            if (from > to)
                return BadRequest(new { message = "from phải nhỏ hơn hoặc bằng to" });

            var result = await _analyticsService.GetRetentionAsync(from, to);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy dữ liệu retention", error = ex.Message });
        }
    }

    /// <summary>
    /// Báo cáo funnel chuyển đổi người dùng
    /// </summary>
    /// <remarks>
    /// Funnel được hỗ trợ: onboarding_to_workout
    /// Các bước:
    ///   1. register_success     – Đăng ký + xác thực email thành công
    ///   2. onboarding_completed – Hoàn thành điền thông tin cá nhân (Customer profile)
    ///   3. workout_plan_created – Đã tạo ít nhất 1 kế hoạch tập
    ///   4. workout_started      – Đã bắt đầu ít nhất 1 buổi tập
    ///   5. workout_completed    – Đã hoàn thành ít nhất 1 buổi tập
    /// ConversionFromPrevious: tỉ lệ chuyển từ bước trước (%).
    /// ConversionFromStart:    tỉ lệ so với bước đầu tiên (%).
    /// DroppedFromPrevious:    số user rớt so với bước trước.
    /// </remarks>
    [HttpGet("funnel")]
    public async Task<IActionResult> GetFunnel(
        [FromQuery] string name = "onboarding_to_workout")
    {
        try
        {
            var result = await _analyticsService.GetFunnelAsync(name);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy dữ liệu funnel", error = ex.Message });
        }
    }

    /// <summary>
    /// Báo cáo sử dụng tính năng trong khoảng thời gian
    /// </summary>
    /// <remarks>
    /// Các tính năng được thống kê:
    /// - Workout:        buổi tập được bắt đầu
    /// - AI Coach:       tin nhắn user gửi cho AI
    /// - Scan Equipment: chưa có dữ liệu tracking (= 0)
    /// - Generate Plan:  kế hoạch tập được tạo mới
    /// - Nutrition:      meal plan được ghi nhận
    /// - Subscription:   subscription mới được kích hoạt
    /// - Profile:        chưa có dữ liệu tracking (= 0)
    /// </remarks>
    [HttpGet("feature-usage")]
    public async Task<IActionResult> GetFeatureUsage(
        [FromQuery] DateTime from,
        [FromQuery] DateTime to)
    {
        try
        {
            if (from > to)
                return BadRequest(new { message = "from phải nhỏ hơn hoặc bằng to" });

            var result = await _analyticsService.GetFeatureUsageAsync(from, to);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy dữ liệu feature usage", error = ex.Message });
        }
    }

    /// <summary>
    /// Báo cáo hành vi tập luyện trong khoảng thời gian
    /// </summary>
    /// <remarks>
    /// Thống kê:
    /// - TotalSessionsStarted:  tổng buổi tập được bắt đầu
    /// - TotalSessionsCompleted: tổng buổi tập hoàn thành (có EndTime)
    /// - CompletionRate:        tỉ lệ hoàn thành (%)
    /// - AverageDurationMinutes: thời lượng trung bình của buổi tập hoàn thành (phút)
    /// - MostPopularExercises:  top 10 bài tập được dùng nhiều nhất
    /// - MostTrainedMuscles:    top 10 nhóm cơ được tập nhiều nhất (theo EXP tích lũy)
    /// - MostConsistentUsers:   top 10 user tập đều nhất (theo số buổi)
    /// </remarks>
    [HttpGet("workouts")]
    public async Task<IActionResult> GetWorkoutAnalytics(
        [FromQuery] DateTime from,
        [FromQuery] DateTime to)
    {
        try
        {
            if (from > to)
                return BadRequest(new { message = "from phải nhỏ hơn hoặc bằng to" });

            var result = await _analyticsService.GetWorkoutAnalyticsAsync(from, to);
            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lấy dữ liệu workout analytics", error = ex.Message });
        }
    }
}
