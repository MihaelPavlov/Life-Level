namespace LifeLevel.Api.Application.DTOs.LoginReward;

public class LoginRewardStatusDto
{
    public int DayInCycle { get; set; }
    public bool ClaimedToday { get; set; }
    public int NextRewardXp { get; set; }
    public bool NextRewardIncludesShield { get; set; }
    public bool NextRewardIsXpStorm { get; set; }
    public int TotalLoginDays { get; set; }
}

public class LoginRewardClaimResult
{
    public int DayInCycle { get; set; }
    public int XpAwarded { get; set; }
    public bool IncludesShield { get; set; }
    public bool IsXpStorm { get; set; }
    public bool LeveledUp { get; set; }
    public int? NewLevel { get; set; }
}
