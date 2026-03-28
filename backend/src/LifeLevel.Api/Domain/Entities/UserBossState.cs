namespace LifeLevel.Api.Domain.Entities;

public class UserBossState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public Guid BossId { get; set; }
    public Boss Boss { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    public UserMapProgress UserMapProgress { get; set; } = null!;
    public int HpDealt { get; set; } = 0;
    public bool IsDefeated { get; set; } = false;
    public DateTime? DefeatedAt { get; set; }
    public DateTime? StartedAt { get; set; }
    public bool IsExpired { get; set; } = false;
}
