using GymCoach.Api.Config;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using CloudinaryDotNet;
using GymSupport.Repository.Repositories;
using GymSupport.Service.Interfaces;
using GymSupport.Service.Services;
using GymSupport.API.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using MongoDB.Driver;
using System.Text.Json.Nodes;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
builder.Services.AddScoped<CloudinaryMediaService>();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "JWT Authorization header using the Bearer scheme"
    });
    
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});
builder.Services.AddSingleton<MongoDbContext>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy => policy.AllowAnyOrigin()
                        .AllowAnyHeader()
                        .AllowAnyMethod());
});

// Jwt configuration
var jwtKey = builder.Configuration["Jwt:Key"] ?? string.Empty;
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? string.Empty;
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? string.Empty;

var key = Encoding.UTF8.GetBytes(jwtKey);
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = false;
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateLifetime = true,  
            ClockSkew = TimeSpan.Zero
        };
        options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
                logger.LogError($"JWT Authentication Failed: {context.Exception.Message}");
                logger.LogError($"Exception: {context.Exception}");
                return Task.CompletedTask;
            }
        };
    });

// Register application services
builder.Services.AddHttpClient();
builder.Services.AddScoped<
    IChatRepository,
    ChatRepository>();

builder.Services.AddScoped<
    IAIService,
    OpenAIService>();

builder.Services.AddScoped<
    IMuscleRepository,
    MuscleRepository>();
builder.Services.AddScoped<IUserMuscleProgressRepository, UserMuscleProgressRepository>();
builder.Services.AddScoped<IUserBadgeRepository, UserBadgeRepository>();
builder.Services.AddScoped<IWorkoutSessionLogService, WorkoutSessionLogService>();
builder.Services.AddScoped<IWorkoutSessionLogRepository, WorkoutSessionLogRepository>();
builder.Services.AddScoped<IExerciseRepository, ExerciseRepository>();
builder.Services.AddScoped<IWorkoutPlanRepository, WorkoutPlanRepository>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IEmailService, SmtpEmailService>();
builder.Services.AddScoped<ITokenService, JwtTokenService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<ICustomerRepository, CustomerRepository>();
builder.Services.AddScoped<IExerciseRepository, ExerciseRepository>();
builder.Services.AddScoped<IWorkoutPlanRepository, WorkoutPlanRepository>();
builder.Services.AddScoped<IUserSubscriptionRepository, UserSubscriptionRepository>();
builder.Services.AddScoped<ISubscriptionPlanRepository, SubscriptionPlanRepository>();
builder.Services.AddScoped<IPaymentRepository, PaymentRepository>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
builder.Services.AddScoped<IMealPlanRepository, MealPlanRepository>();
builder.Services.AddScoped<ISubscriptionService, SubscriptionService>();
builder.Services.AddScoped<IStorePurchaseService, StorePurchaseService>();
builder.Services.AddScoped<PremiumOnlyFilter>();
builder.Services.AddSingleton(sp => {
    var config = sp.GetRequiredService<IConfiguration>();
    var clientId = config["PayOS:ClientId"] ?? throw new InvalidOperationException("PayOS ClientId is missing.");
    var apiKey = config["PayOS:ApiKey"] ?? throw new InvalidOperationException("PayOS ApiKey is missing.");
    var checksumKey = config["PayOS:ChecksumKey"] ?? throw new InvalidOperationException("PayOS ChecksumKey is missing.");
    return new PayOS.PayOSClient(clientId, apiKey, checksumKey);
});






var app = builder.Build();

// Configure the HTTP request pipeline.
using (var scope = app.Services.CreateScope())
{
    try
    {
        var dbContext = scope.ServiceProvider.GetRequiredService<MongoDbContext>();
        var exerciseCollection = dbContext.GetCollection<Exercise>("Exercises");
        var muscleCollection = dbContext.GetCollection<Muscle>("Muscles");

        // --- Database Migration: Seed/Update Subscription Plans ---
        var planCollection = dbContext.GetCollection<SubscriptionPlan>("SubscriptionPlans");
        
        // 1. Rename existing premium_monthly or Premium Monthly or hội viên tháng, and set price to 5000
        var monthlyFilter = Builders<SubscriptionPlan>.Filter.Or(
            Builders<SubscriptionPlan>.Filter.Eq(p => p.Name, "premium_monthly"),
            Builders<SubscriptionPlan>.Filter.Eq(p => p.Name, "Premium Monthly"),
            Builders<SubscriptionPlan>.Filter.Eq(p => p.Name, "hội viên tháng")
        );
        var monthlyPlan = await planCollection.Find(monthlyFilter).FirstOrDefaultAsync();
        if (monthlyPlan != null)
        {
            monthlyPlan.Name = "hội viên tháng";
            monthlyPlan.Price = 5000;
            await planCollection.ReplaceOneAsync(p => p.Id == monthlyPlan.Id, monthlyPlan);
            Console.WriteLine("--> Database Migration: Updated monthly plan to 'hội viên tháng' and price to 5000");
        }
        
        // 2. Rename existing premium_yearly or Premium Yearly or hội viên năm, and set price to 10000
        var yearlyFilter = Builders<SubscriptionPlan>.Filter.Or(
            Builders<SubscriptionPlan>.Filter.Eq(p => p.Name, "premium_yearly"),
            Builders<SubscriptionPlan>.Filter.Eq(p => p.Name, "Premium Yearly"),
            Builders<SubscriptionPlan>.Filter.Eq(p => p.Name, "hội viên năm")
        );
        var yearlyPlan = await planCollection.Find(yearlyFilter).FirstOrDefaultAsync();
        if (yearlyPlan != null)
        {
            yearlyPlan.Name = "hội viên năm";
            yearlyPlan.Price = 10000;
            await planCollection.ReplaceOneAsync(p => p.Id == yearlyPlan.Id, yearlyPlan);
            Console.WriteLine("--> Database Migration: Updated yearly plan to 'hội viên năm' and price to 10000");
        }

        var existingPlans = await planCollection.Find(_ => true).ToListAsync();
        if (existingPlans.Count == 0)
        {
            Console.WriteLine("--> Seeding Subscription Plans...");
            var monthly = new SubscriptionPlan
            {
                Name = "hội viên tháng",
                DurationMonths = 1,
                Price = 5000,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };
            var yearly = new SubscriptionPlan
            {
                Name = "hội viên năm",
                DurationMonths = 12,
                Price = 10000,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };
            await planCollection.InsertOneAsync(monthly);
            await planCollection.InsertOneAsync(yearly);
            Console.WriteLine("--> Successfully seeded 'hội viên tháng' and 'hội viên năm'!");
        }

        // Lấy danh sách muscles để map ID
        var muscles = await muscleCollection.Find(_ => true).ToListAsync();
        var muscleMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var m in muscles)
        {
            if (!string.IsNullOrWhiteSpace(m.Name) && !string.IsNullOrWhiteSpace(m.Id))
            {
                muscleMap[m.Name.Trim()] = m.Id;
            }
        }

        // Kiểm tra xem database có chứa exercises rỗng hoặc trống không
        var existingExercises = await exerciseCollection.Find(_ => true).ToListAsync();
        var hasValidExercises = existingExercises.Any(e => !string.IsNullOrEmpty(e.Name));

        if (!hasValidExercises && muscles.Count > 0)
        {
            Console.WriteLine("--> SeedData: Exercises collection is empty or invalid. Starting automatic seed...");
            var seedPath = Path.Combine(app.Environment.ContentRootPath, "SeedData", "exercises.seed.json");
            if (!File.Exists(seedPath))
            {
                seedPath = Path.Combine(app.Environment.ContentRootPath, "..", "SeedData", "exercises.seed.json");
            }

            if (File.Exists(seedPath))
            {
                var seedJson = await File.ReadAllTextAsync(seedPath);
                var rawSeedList = System.Text.Json.JsonSerializer.Deserialize<List<System.Text.Json.Nodes.JsonNode>>(seedJson);

                if (rawSeedList != null)
                {
                    // Xóa dữ liệu cũ không hợp lệ (nếu có)
                    await exerciseCollection.DeleteManyAsync(Builders<Exercise>.Filter.Empty);

                    var toInsert = new List<Exercise>();
                    foreach (var node in rawSeedList)
                    {
                        var name = node["name"]?.ToString();
                        var equipment = node["equipment"]?.ToString();
                        var difficulty = node["difficulty"]?.ToString();
                        var sets = node["sets"]?.GetValue<int>() ?? 3;
                        var reps = node["reps"]?.ToString() ?? "10";
                        var rest = node["rest"]?.GetValue<int>() ?? 60;
                        var primaryMuscle = node["primaryMuscle"]?.ToString();
                        var secondaryNodes = node["secondaryMuscles"]?.AsArray();

                        if (string.IsNullOrEmpty(name) || string.IsNullOrEmpty(primaryMuscle)) continue;

                        var impacts = new List<MuscleImpact>();
                        if (muscleMap.TryGetValue(primaryMuscle.Trim(), out var primaryId))
                        {
                            var secList = new List<string>();
                            if (secondaryNodes != null)
                            {
                                foreach (var secNode in secondaryNodes)
                                {
                                    var val = secNode?.ToString();
                                    if (!string.IsNullOrEmpty(val)) secList.Add(val.Trim());
                                }
                            }

                            if (secList.Count == 0)
                            {
                                impacts.Add(new MuscleImpact { MuscleId = primaryId, Percentage = 100 });
                            }
                            else if (secList.Count == 1)
                            {
                                impacts.Add(new MuscleImpact { MuscleId = primaryId, Percentage = 70 });
                                if (muscleMap.TryGetValue(secList[0], out var secId))
                                {
                                    impacts.Add(new MuscleImpact { MuscleId = secId, Percentage = 30 });
                                }
                            }
                            else
                            {
                                impacts.Add(new MuscleImpact { MuscleId = primaryId, Percentage = 60 });
                                foreach (var sec in secList)
                                {
                                    if (muscleMap.TryGetValue(sec, out var secId))
                                    {
                                        impacts.Add(new MuscleImpact { MuscleId = secId, Percentage = 20 });
                                    }
                                }
                            }

                            toInsert.Add(new Exercise
                            {
                                Name = name,
                                Equipment = equipment ?? "",
                                Difficulty = difficulty ?? "Beginner",
                                Description = $"{name} là bài tập tập trung chủ yếu vào {primaryMuscle}.",
                                Instruction = "Thiết lập dụng cụ và tư thế ổn định. Thực hiện chuyển động chậm, có kiểm soát; thở ra ở pha gắng sức và hít vào khi trở về.",
                                SafetyNotes = "Ưu tiên kỹ thuật trước mức tạ. Dừng bài tập nếu đau nhói, chóng mặt hoặc mất kiểm soát tư thế.",
                                CommonMistakes = "Dùng mức tạ quá nặng, thực hiện quá nhanh, nín thở hoặc đánh đổi tư thế để hoàn thành số lần lặp.",
                                Tips = "Bắt đầu nhẹ, giữ nhịp ổn định và tăng tải dần khi hoàn thành toàn bộ số lần lặp với kỹ thuật tốt.",
                                DefaultSets = sets,
                                DefaultReps = reps,
                                RestTimeSeconds = rest,
                                ImageUrl = "",
                                VideoUrl = "",
                                MuscleImpacts = impacts
                            });
                        }
                    }

                    if (toInsert.Count > 0)
                    {
                        await exerciseCollection.InsertManyAsync(toInsert);
                        Console.WriteLine($"--> SeedData: Successfully imported {toInsert.Count} exercises into MongoDB!");
                    }
                }
            }
            else
            {
                Console.WriteLine($"--> SeedData Warning: exercises.seed.json not found at {seedPath}");
            }
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"--> SeedData Error: {ex.Message}");
    }
}
// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//if (!app.Environment.IsDevelopment())
//{
//    app.UseHttpsRedirection();
//}

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
