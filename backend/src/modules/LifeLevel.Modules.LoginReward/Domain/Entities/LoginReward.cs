namespace LifeLevel.Modules.LoginReward.Domain.Entities;

public class LoginReward
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public int DayInCycle { get; set; }
    public DateTime? LastClaimedAt { get; set; }
    public bool ClaimedToday { get; set; }
    public int TotalLoginDays { get; set; }
}
