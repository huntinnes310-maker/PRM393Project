namespace GymSupport.Repository.Models.DTOs.AIModel;

public class AiUsageQuotaDto
{
    public int Used { get; set; }

    public int Limit { get; set; }
}

public class AiUsageSnapshotDto
{
    public bool IsPremium { get; set; }

    public AiUsageQuotaDto Chat { get; set; } = new();

    public AiUsageQuotaDto Generate { get; set; } = new();

    public AiUsageQuotaDto Analyze { get; set; } = new();

    public AiUsageQuotaDto Evaluate { get; set; } = new();

    public bool BudgetExhausted { get; set; }
}
