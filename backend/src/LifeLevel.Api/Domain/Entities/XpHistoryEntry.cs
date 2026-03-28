namespace LifeLevel.Api.Domain.Entities;

public class XpHistoryEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CharacterId { get; set; }
    public Character Character { get; set; } = null!;

    public string Source { get; set; } = string.Empty;       // e.g. "Activity", "DailyQuest", "StreakBonus", "BossDefeated", "LevelUp", "CharacterSetup"
    public string SourceEmoji { get; set; } = string.Empty;  // e.g. "🏃", "📋", "🔥", "⚔️", "🌟", "✨"
    public string Description { get; set; } = string.Empty;  // e.g. "Morning Run · 5.2 km"
    public long Xp { get; set; }
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
}
