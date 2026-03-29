namespace LifeLevel.Api.Domain.Entities;

public class Streak
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public int Current { get; set; }
    public int Longest { get; set; }
    public DateTime? LastActivityDate { get; set; }  // UTC date only
    public int ShieldsAvailable { get; set; }
    public int ShieldsUsed { get; set; }
    public bool ShieldUsedToday { get; set; }
    public int TotalDaysActive { get; set; }
}
