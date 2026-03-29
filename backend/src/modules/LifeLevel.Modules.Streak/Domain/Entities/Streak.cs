namespace LifeLevel.Modules.Streak.Domain.Entities;

public class Streak
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public int Current { get; set; }
    public int Longest { get; set; }
    public DateTime? LastActivityDate { get; set; }
    public int ShieldsAvailable { get; set; }
    public int ShieldsUsed { get; set; }
    public bool ShieldUsedToday { get; set; }
    public int TotalDaysActive { get; set; }
}
