using LifeLevel.Modules.Talents.Domain.Enums;

namespace LifeLevel.Modules.Talents.Domain.Entities;

/// <summary>Audit trail of every successful draw and the authoritative source for progressive pricing.</summary>
public class TalentDrawEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public DateTime DrawnAt { get; set; } = DateTime.UtcNow;

    public TalentDrawKind Kind { get; set; }
    public Guid TalentId { get; set; }
    public int CrystalsAwarded { get; set; }
    public int DrawNumber { get; set; }
    public int CoinsSpent { get; set; }
    public int CrystalsSpent { get; set; }
}
