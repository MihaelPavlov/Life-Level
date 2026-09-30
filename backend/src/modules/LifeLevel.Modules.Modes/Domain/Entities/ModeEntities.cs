namespace LifeLevel.Modules.Modes.Domain.Entities;

public class BurnChainRun
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public DateTime StartedAtUtc { get; set; }
    public DateTime EndsAtUtc { get; set; }
    public DateTime? EndedAtUtc { get; set; }
    public string? EndReason { get; set; }
    public string LinksJson { get; set; } = "[]";
    public int AcknowledgedLinks { get; set; }
    public int CoinsAwarded { get; set; }
    public int TalentCrystalsAwarded { get; set; }
    public DateTime? CollectedAtUtc { get; set; }
}

public class TreasureDelveRun
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public DateTime EntryDateUtc { get; set; }
    public DateTime StartedAtUtc { get; set; }
    public DateTime UpdatedAtUtc { get; set; }
    public string Phase { get; set; } = "choosing";
    public string? EndReason { get; set; }
    public int Chamber { get; set; }
    public string FeaturedStat { get; set; } = "str";
    public int Strength { get; set; }
    public int Endurance { get; set; }
    public int Agility { get; set; }
    public int Flexibility { get; set; }
    public int Stamina { get; set; }
    public int SecuredCoins { get; set; }
    public int AtRiskCoins { get; set; }
    public int RoomsCleared { get; set; }
    public string OptionsJson { get; set; } = "[]";
    public string? ChosenPath { get; set; }
    public string HistoryJson { get; set; } = "[]";
    public string ItemsJson { get; set; } = "[]";
    public int CoinsAwarded { get; set; }
    public int TalentCrystalsAwarded { get; set; }
    public DateTime? SettledAtUtc { get; set; }
    public DateTime? AcknowledgedAtUtc { get; set; }
}

public class ModeRewardSettlement
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Mode { get; set; } = string.Empty;
    public Guid RunId { get; set; }
    public int Coins { get; set; }
    public int TalentCrystals { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
