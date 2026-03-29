namespace LifeLevel.Modules.Adventure.Encounters.Domain.Entities;

public class UserBossState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    // No User nav prop — cross-module
    public Guid BossId { get; set; }
    public Boss Boss { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    // No UserMapProgress nav prop — cross-module (UserMapProgress is in Map module)
    public int HpDealt { get; set; } = 0;
    public bool IsDefeated { get; set; } = false;
    public DateTime? DefeatedAt { get; set; }
    public DateTime? StartedAt { get; set; }
    public bool IsExpired { get; set; } = false;
}
