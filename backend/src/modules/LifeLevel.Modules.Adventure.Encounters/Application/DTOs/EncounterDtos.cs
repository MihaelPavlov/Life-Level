namespace LifeLevel.Modules.Adventure.Encounters.Application.DTOs;

public class BossDamageResult
{
    public int HpDealt { get; set; }
    public int MaxHp { get; set; }
    public bool IsDefeated { get; set; }
    public bool JustDefeated { get; set; }
    public int RewardXpAwarded { get; set; }
}

public class CollectChestResult
{
    public int RewardXp { get; set; }
    public string Rarity { get; set; } = string.Empty;
    public DateTime CollectedAt { get; set; }
}
