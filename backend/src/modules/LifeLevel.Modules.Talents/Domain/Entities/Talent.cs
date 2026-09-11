using LifeLevel.Modules.Talents.Domain.Enums;

namespace LifeLevel.Modules.Talents.Domain.Entities;

/// <summary>
/// Catalog row for one talent. Seeded from <c>TalentCatalog</c>, admin-editable. Never per-user.
/// </summary>
public class Talent
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>Stable slug, e.g. "focused-training". Used by the mobile client and the upgrade route.</summary>
    public string Key { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;

    /// <summary>Icon key resolved client-side (prefix-based, like season icon keys).</summary>
    public string IconKey { get; set; } = string.Empty;

    public TalentRarity Rarity { get; set; } = TalentRarity.Common;
    public TalentEffectType EffectType { get; set; }

    /// <summary>Effect magnitude added per level (percent points, stat points, or count).</summary>
    public double PerLevelValue { get; set; }

    public int MaxLevel { get; set; } = 10;

    /// <summary>Relative weight when a draw rolls a brand-new talent.</summary>
    public int DrawWeight { get; set; } = 100;

    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}
