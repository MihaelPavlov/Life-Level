namespace LifeLevel.Api.Application.DTOs.Streak;

public class StreakDto
{
    public int Current { get; set; }
    public int Longest { get; set; }
    public int ShieldsAvailable { get; set; }
    public bool ShieldUsedToday { get; set; }
    public DateTime? LastActivityDate { get; set; }
    public int TotalDaysActive { get; set; }
}

public class UseShieldResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public int ShieldsRemaining { get; set; }
}
