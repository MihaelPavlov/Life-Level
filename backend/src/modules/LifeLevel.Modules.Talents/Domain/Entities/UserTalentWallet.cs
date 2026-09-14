namespace LifeLevel.Modules.Talents.Domain.Entities;

/// <summary>
/// Per-user talent economy. Lazily created on first read/credit. One row per user.
/// </summary>
public class UserTalentWallet
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    /// <summary>Soft currency — earned from activities / quests / bosses. Spent on draws + upgrades.</summary>
    public long Coins { get; set; }

    /// <summary>Scarce hard currency — earned only from bosses, zone/region completions, and reward claims. Spent on draws + upgrades.</summary>
    public int Crystals { get; set; }

    /// <summary>Rolling weekly count of Second Wind auto-recoveries used (reset by the streak day-key check).</summary>
    public int SecondWindUsedThisWeek { get; set; }

    /// <summary>ISO week key (yyyy-Www) the SecondWind counter belongs to.</summary>
    public string? SecondWindWeekKey { get; set; }

    /// <summary>Set by the StreakBroken handler; feeds the Steel Resolve comeback window.</summary>
    public DateTime? LastStreakBrokenAt { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
