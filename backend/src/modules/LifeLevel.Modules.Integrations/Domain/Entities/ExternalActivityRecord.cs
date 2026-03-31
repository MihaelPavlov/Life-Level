namespace LifeLevel.Modules.Integrations.Domain.Entities;

public class ExternalActivityRecord
{
    public Guid Id { get; set; }
    public Guid CharacterId { get; set; }
    public string Provider { get; set; } = string.Empty;    // "HealthKit" | "HealthConnect" | "Strava"
    public string ExternalId { get; set; } = string.Empty;  // provider-scoped native ID
    public DateTime ActivityStartTime { get; set; }
    public bool WasImported { get; set; }
    public Guid? ImportedActivityId { get; set; }           // FK to Activity if WasImported
    public DateTime SyncedAt { get; set; }
}
