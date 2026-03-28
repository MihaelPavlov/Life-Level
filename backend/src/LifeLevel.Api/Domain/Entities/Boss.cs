namespace LifeLevel.Api.Domain.Entities;

public class Boss
{
    public Guid Id { get; set; }
    public Guid NodeId { get; set; }
    public MapNode Node { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public int MaxHp { get; set; }
    public int RewardXp { get; set; }
    public int TimerDays { get; set; } = 7;
    /// <summary>
    /// Mini-bosses do not require the player to be at the boss node.
    /// They use a 3-day timer and have smaller rewards.
    /// </summary>
    public bool IsMini { get; set; } = false;

    public ICollection<UserBossState> UserStates { get; set; } = [];
}
