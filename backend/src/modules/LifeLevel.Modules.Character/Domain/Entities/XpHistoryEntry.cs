namespace LifeLevel.Modules.Character.Domain.Entities;

public class XpHistoryEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CharacterId { get; set; }

    public string Source { get; set; } = string.Empty;
    public string SourceEmoji { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public long Xp { get; set; }
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
}
