namespace LifeLevel.Modules.Character.Domain.Entities;

public class RankThreshold
{
    public Guid Id { get; set; }
    public string Rank { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int BossesRequired { get; set; }
}
