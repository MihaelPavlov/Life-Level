using LifeLevel.Modules.Talents.Domain.Enums;

namespace LifeLevel.Modules.Talents.Domain.Entities;

/// <summary>Audit trail of every draw. Not read by gameplay in v1; kept for balancing / future pity.</summary>
public class TalentDrawEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public DateTime DrawnAt { get; set; } = DateTime.UtcNow;

    public TalentDrawKind Kind { get; set; }
    public Guid TalentId { get; set; }
    public int ShardsAwarded { get; set; }
}
