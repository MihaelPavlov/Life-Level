namespace LifeLevel.Modules.Adventure.Encounters.Application.DTOs;

public class BossDamageResult
{
    public int HpDealt { get; set; }
    public int MaxHp { get; set; }
    public bool IsDefeated { get; set; }
    public bool JustDefeated { get; set; }
    public int RewardXpAwarded { get; set; }
}

public class BossListItemDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public int MaxHp { get; set; }
    public int RewardXp { get; set; }
    public int TimerDays { get; set; }
    public bool IsMini { get; set; }
    public string Region { get; set; } = string.Empty;
    public string NodeName { get; set; } = string.Empty;
    public int LevelRequirement { get; set; }

    // Gameplay
    public bool CanFight { get; set; }

    // User state
    public bool Activated { get; set; }
    public int HpDealt { get; set; }
    public bool IsDefeated { get; set; }
    public bool IsExpired { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? TimerExpiresAt { get; set; }
    public DateTime? DefeatedAt { get; set; }
}

public class CollectChestResult
{
    public int RewardXp { get; set; }
    public string Rarity { get; set; } = string.Empty;
    public DateTime CollectedAt { get; set; }
}
