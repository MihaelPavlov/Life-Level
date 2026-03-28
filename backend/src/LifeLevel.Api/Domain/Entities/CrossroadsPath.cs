using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Domain.Entities;

public class CrossroadsPath
{
    public Guid Id { get; set; }
    public Guid CrossroadsId { get; set; }
    public Crossroads Crossroads { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public double DistanceKm { get; set; }
    public CrossroadsPathDifficulty Difficulty { get; set; }
    public int EstimatedDays { get; set; }
    public int RewardXp { get; set; }
    public string? AdditionalRequirement { get; set; }
    public Guid? LeadsToNodeId { get; set; }
    public MapNode? LeadsToNode { get; set; }
}
