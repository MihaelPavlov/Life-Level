namespace LifeLevel.Modules.Adventure.Encounters.Domain.Entities;

public class Boss
{
    public Guid Id { get; set; }
    public Guid NodeId { get; set; }
    // No MapNode nav prop — cross-module FK configured in AppDbContext
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public int MaxHp { get; set; }
    public int RewardXp { get; set; }
    public int TimerDays { get; set; } = 7;
    public bool IsMini { get; set; } = false;

    public ICollection<UserBossState> UserStates { get; set; } = [];
}
