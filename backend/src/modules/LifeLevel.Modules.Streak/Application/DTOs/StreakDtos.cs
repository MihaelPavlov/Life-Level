namespace LifeLevel.Modules.Streak.Application.DTOs;

public class StreakDto
{
    public int Current { get; set; }
    public int Longest { get; set; }
    public int ShieldsAvailable { get; set; }
    public bool ShieldUsedToday { get; set; }
    public DateTime? LastActivityDate { get; set; }
    public int TotalDaysActive { get; set; }
}

public class StreakUpdateResult
{
    public bool Updated { get; set; }
    public bool ShieldUsed { get; set; }
    public bool StreakBroke { get; set; }
    public int Current { get; set; }
    public bool ShieldAwarded { get; set; }
}

public class UseShieldResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public int ShieldsRemaining { get; set; }
}
