namespace LifeLevel.Modules.Guild.Domain.Entities;

public class GuildRaid
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid GuildId { get; set; }
    public Guid BossId { get; set; }
    public Guid StartedByUserId { get; set; }
    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public int MaxHp { get; set; }
    public int Armor { get; set; }
    public int RewardXp { get; set; }
    public int GuildSizeAtStart { get; set; }
    public int TotalDamage { get; set; }
    public bool IsDefeated { get; set; }
    public bool IsExpired { get; set; }
    public DateTime? DefeatedAt { get; set; }
    public DateTime? RewardClaimedAt { get; set; }

    public Guild Guild { get; set; } = null!;
    public ICollection<GuildRaidContribution> Contributions { get; set; } = [];
}
