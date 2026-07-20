using GymSupport.Repository.Models.Entities;
using Microsoft.Extensions.Configuration;
using MongoDB.Driver;
namespace GymCoach.Api.Config;

public class MongoDbContext
{
    private readonly IMongoDatabase _database;

    public MongoDbContext(IConfiguration config)
    {
        var connectionString = config["MongoDbSettings:ConnectionString"];
        var dbName = config["MongoDbSettings:DatabaseName"];

        var client = new MongoClient(connectionString);
        _database = client.GetDatabase(dbName);
    }

    public IMongoCollection<T> GetCollection<T>(string name)
        => _database.GetCollection<T>(name);

    public IMongoCollection<ChatMessage> ChatMessages =>
    GetCollection<ChatMessage>("ChatMessages");

    public IMongoCollection<AiMonthlyBudget> AiMonthlyBudgets =>
        GetCollection<AiMonthlyBudget>("AiMonthlyBudgets");

    public IMongoCollection<AiUsageLog> AiUsageLogs =>
        GetCollection<AiUsageLog>("AiUsageLogs");

    public IMongoCollection<AiDailyQuota> AiDailyQuotas =>
        GetCollection<AiDailyQuota>("AiDailyQuotas");
}
