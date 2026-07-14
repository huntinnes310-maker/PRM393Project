using GymCoach.Api.Config;
using GymSupport.Repository.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MongoDB.Bson;
using MongoDB.Driver;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace GymSupport.API.Controllers;

[ApiController]
[Route("api/nutrition")]
[Authorize]
public class NutritionController : ControllerBase
{
    private readonly IMongoCollection<MealPlan> _mealPlansCollection;
    private readonly IMongoCollection<Customer> _customersCollection;

    public NutritionController(MongoDbContext context)
    {
        _mealPlansCollection = context.GetCollection<MealPlan>("MealPlans");
        _customersCollection = context.GetCollection<Customer>("Customers");
    }

    private string? GetCurrentUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

    [HttpGet("today")]
    public async Task<IActionResult> GetTodayNutrition([FromQuery] string userId, [FromQuery] string date)
    {
        if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(date))
            return BadRequest("UserId và Date là bắt buộc.");

        var currentUserId = GetCurrentUserId();
        if (currentUserId != userId)
            return Forbid();

        var parsedDate = DateTime.Parse(date);
        var startOfDay = parsedDate.Date;
        var endOfDay = parsedDate.Date.AddDays(1).AddTicks(-1);

        var mealPlan = await _mealPlansCollection
            .Find(x => x.UserId == userId && x.Date >= startOfDay && x.Date <= endOfDay)
            .FirstOrDefaultAsync();

        // Calculate goals dynamically
        double caloriesGoal = 2000;
        int proteinGoal = 100;
        double waterGoal = 2.0;
        int carbsGoal = 250;
        int fatGoal = 65;

        var customer = await _customersCollection.Find(c => c.UserId == userId).FirstOrDefaultAsync();
        if (customer != null)
        {
            var weight = customer.WeightKg;
            var height = customer.HeightCm;
            var age = customer.Age;

            if (weight > 0)
            {
                proteinGoal = (int)Math.Round(weight * 1.8);
                waterGoal = Math.Round(weight * 30 / 1000.0, 1);
            }

            if (weight > 0 && height > 0 && age > 0)
            {
                var gender = customer.Gender?.ToLowerInvariant() ?? "";
                var goal = customer.Goal?.ToLowerInvariant() ?? "";
                var bmr = gender.Contains("nữ") || gender.Contains("female")
                    ? 10 * weight + 6.25 * height - 5 * age - 161
                    : 10 * weight + 6.25 * height - 5 * age + 5;

                var c = bmr * 1.45;
                if (goal.Contains("giảm") || goal.Contains("lose"))
                    c -= 300;
                else if (goal.Contains("tăng cơ") || goal.Contains("strength") || goal.Contains("muscle"))
                    c += 250;

                caloriesGoal = Math.Round(c);
                carbsGoal = (int)Math.Round((caloriesGoal * 0.5) / 4);
                fatGoal = (int)Math.Round((caloriesGoal * 0.25) / 9);
            }
        }

        if (mealPlan == null)
        {
            return Ok(new
            {
                userId = userId,
                date = date,
                caloriesGoal = caloriesGoal,
                caloriesLogged = 0,
                proteinGoal = proteinGoal,
                proteinLogged = 0,
                carbsGoal = carbsGoal,
                carbsLogged = 0,
                fatGoal = fatGoal,
                fatLogged = 0,
                waterGoal = waterGoal,
                waterLogged = 0.0,
                meals = new List<MealItem>()
            });
        }

        return Ok(new
        {
            userId = userId,
            date = date,
            caloriesGoal = caloriesGoal,
            caloriesLogged = mealPlan.TotalCalories,
            proteinGoal = proteinGoal,
            proteinLogged = mealPlan.Protein,
            carbsGoal = carbsGoal,
            carbsLogged = mealPlan.Carbs,
            fatGoal = fatGoal,
            fatLogged = mealPlan.Fat,
            waterGoal = waterGoal,
            waterLogged = mealPlan.WaterLiters,
            meals = mealPlan.Meals ?? new List<MealItem>()
        });
    }

    [HttpPost("water")]
    public async Task<IActionResult> LogWater([FromBody] LogWaterRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.UserId) || string.IsNullOrWhiteSpace(request.Date))
            return BadRequest("Dữ liệu yêu cầu không hợp lệ.");

        var currentUserId = GetCurrentUserId();
        if (currentUserId != request.UserId)
            return Forbid();

        var parsedDate = DateTime.Parse(request.Date);
        var startOfDay = parsedDate.Date;
        var endOfDay = parsedDate.Date.AddDays(1).AddTicks(-1);

        var mealPlan = await _mealPlansCollection
            .Find(x => x.UserId == request.UserId && x.Date >= startOfDay && x.Date <= endOfDay)
            .FirstOrDefaultAsync();

        if (mealPlan == null)
        {
            mealPlan = new MealPlan
            {
                Id = ObjectId.GenerateNewId().ToString(),
                UserId = request.UserId,
                Date = parsedDate.Date,
                TotalCalories = 0,
                Protein = 0,
                Carbs = 0,
                Fat = 0,
                WaterLiters = 0.0,
                Meals = new List<MealItem>()
            };
        }

        mealPlan.WaterLiters = Math.Max(0.0, mealPlan.WaterLiters + request.Liters);

        await _mealPlansCollection.ReplaceOneAsync(
            x => x.UserId == mealPlan.UserId && x.Date >= startOfDay && x.Date <= endOfDay,
            mealPlan,
            new ReplaceOptions { IsUpsert = true });

        return Ok(new { success = true, waterLogged = mealPlan.WaterLiters });
    }

    [HttpPost("meal")]
    public async Task<IActionResult> LogMeal([FromBody] LogMealRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.UserId) || string.IsNullOrWhiteSpace(request.Date) || string.IsNullOrWhiteSpace(request.Name))
            return BadRequest("Dữ liệu yêu cầu không hợp lệ.");

        var currentUserId = GetCurrentUserId();
        if (currentUserId != request.UserId)
            return Forbid();

        var parsedDate = DateTime.Parse(request.Date);
        var startOfDay = parsedDate.Date;
        var endOfDay = parsedDate.Date.AddDays(1).AddTicks(-1);

        var mealPlan = await _mealPlansCollection
            .Find(x => x.UserId == request.UserId && x.Date >= startOfDay && x.Date <= endOfDay)
            .FirstOrDefaultAsync();

        if (mealPlan == null)
        {
            mealPlan = new MealPlan
            {
                Id = ObjectId.GenerateNewId().ToString(),
                UserId = request.UserId,
                Date = parsedDate.Date,
                TotalCalories = 0,
                Protein = 0,
                Carbs = 0,
                Fat = 0,
                WaterLiters = 0.0,
                Meals = new List<MealItem>()
            };
        }

        mealPlan.TotalCalories += request.Calories;
        mealPlan.Protein += request.Protein;
        mealPlan.Carbs += request.Carbs;
        mealPlan.Fat += request.Fat;

        mealPlan.Meals.Add(new MealItem
        {
            Type = request.Type ?? "Snack",
            Name = request.Name,
            Calories = request.Calories
        });

        await _mealPlansCollection.ReplaceOneAsync(
            x => x.UserId == mealPlan.UserId && x.Date >= startOfDay && x.Date <= endOfDay,
            mealPlan,
            new ReplaceOptions { IsUpsert = true });

        return Ok(new { success = true });
    }

    [HttpDelete("meal/{index}")]
    public async Task<IActionResult> DeleteMeal(int index, [FromQuery] string userId, [FromQuery] string date)
    {
        if (string.IsNullOrWhiteSpace(userId) || string.IsNullOrWhiteSpace(date))
            return BadRequest("UserId và Date là bắt buộc.");

        var currentUserId = GetCurrentUserId();
        if (currentUserId != userId)
            return Forbid();

        var parsedDate = DateTime.Parse(date);
        var startOfDay = parsedDate.Date;
        var endOfDay = parsedDate.Date.AddDays(1).AddTicks(-1);

        var mealPlan = await _mealPlansCollection
            .Find(x => x.UserId == userId && x.Date >= startOfDay && x.Date <= endOfDay)
            .FirstOrDefaultAsync();

        if (mealPlan == null || mealPlan.Meals == null || index < 0 || index >= mealPlan.Meals.Count)
            return BadRequest("Không tìm thấy món ăn để xóa.");

        var targetMeal = mealPlan.Meals[index];
        
        // Note: MealItem only stores Calories. We subtract Calories.
        // For macros like protein/carbs/fat, because we do not store them on individual MealItem,
        // we can either subtract them proportionally or set them based on a simplified formula,
        // or just subtract calories and scale macros proportionally based on total ratios.
        // Let's scale macros down proportionally to avoid numbers going below zero:
        double ratio = mealPlan.TotalCalories > 0 
            ? (double)(mealPlan.TotalCalories - targetMeal.Calories) / mealPlan.TotalCalories
            : 0;

        mealPlan.TotalCalories = Math.Max(0, mealPlan.TotalCalories - targetMeal.Calories);
        mealPlan.Protein = (int)Math.Max(0, Math.Round(mealPlan.Protein * ratio));
        mealPlan.Carbs = (int)Math.Max(0, Math.Round(mealPlan.Carbs * ratio));
        mealPlan.Fat = (int)Math.Max(0, Math.Round(mealPlan.Fat * ratio));

        mealPlan.Meals.RemoveAt(index);

        await _mealPlansCollection.ReplaceOneAsync(
            x => x.UserId == mealPlan.UserId && x.Date >= startOfDay && x.Date <= endOfDay,
            mealPlan,
            new ReplaceOptions { IsUpsert = true });

        return Ok(new { success = true });
    }
}

public class LogWaterRequest
{
    public string UserId { get; set; } = "";
    public string Date { get; set; } = "";
    public double Liters { get; set; }
}

public class LogMealRequest
{
    public string UserId { get; set; } = "";
    public string Date { get; set; } = "";
    public string Type { get; set; } = "Snack"; // Breakfast, Lunch, Dinner, Snack
    public string Name { get; set; } = "";
    public int Calories { get; set; }
    public int Protein { get; set; }
    public int Carbs { get; set; }
    public int Fat { get; set; }
}
