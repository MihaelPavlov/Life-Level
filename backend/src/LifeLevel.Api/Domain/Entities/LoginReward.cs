namespace LifeLevel.Api.Domain.Entities;

public class LoginReward
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public int DayInCycle { get; set; }        // 1–7 (0 = never claimed)
    public DateTime? LastClaimedAt { get; set; }
    public bool ClaimedToday { get; set; }
    public int TotalLoginDays { get; set; }
}
