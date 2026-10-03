namespace LifeLevel.Api.Infrastructure.Persistence;

public sealed class MaintenanceRun
{
    public string Name { get; set; } = string.Empty;
    public DateTime CompletedForUtcDate { get; set; }
    public DateTime CompletedAtUtc { get; set; }
}
