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

builder.Services.AddScoped<IAiUsageRepository, AiUsageRepository>();
builder.Services.AddScoped<IAiUsageService, AiUsageService>();
builder.Services.AddScoped<IWorkoutEvaluationService, WorkoutEvaluationService>();

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
builder.Services.AddScoped<IPayOsService, PayOsService>();
builder.Services.AddHostedService<SubscriptionExpiryWorker>();
builder.Services.AddScoped<PremiumOnlyFilter>();






var app = builder.Build();

//using (var scope = app.Services.CreateScope())
//{
//    var userRepo = scope.ServiceProvider.GetRequiredService<IUserRepository>();

//    var admin = await userRepo.GetByEmailAsync("admin@gym.com");
//    if (admin == null)
//    {
//        var newAdmin = new User
//        {
//            FullName = "Admin",
//            Email = "nkg109204@gmail.com",
//            PasswordHash = BCrypt.Net.BCrypt.HashPassword("12345"),
//            Role = "Admin",
//            CreatedAt = DateTime.UtcNow,
//            IsEmailVerified = true,
//            VerifiedAt = DateTime.UtcNow
//        };

//        await userRepo.CreateAsync(newAdmin);
//    }
//}
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
