namespace LifeLevel.Modules.Talents.Domain.Entities;

/// <summary>
/// A talent a user owns. Presence of the row = owned. One row per (user, talent).
/// </summary>
public class UserTalent
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public Guid TalentId { get; set; }

    /// <summary>1..Talent.MaxLevel.</summary>
    public int Level { get; set; } = 1;

    /// <summary>Unspent duplicate shards for this talent (from draws).</summary>
    public int Shards { get; set; }

    public DateTime UnlockedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
