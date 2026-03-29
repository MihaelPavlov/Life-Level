using LifeLevel.Modules.Adventure.Encounters.Domain.Enums;

namespace LifeLevel.Modules.Adventure.Encounters.Domain.Entities;

public class Chest
{
    public Guid Id { get; set; }
    public Guid NodeId { get; set; }
    // No MapNode nav prop — cross-module FK configured in AppDbContext
    public ChestRarity Rarity { get; set; }
    public int RewardXp { get; set; }

    public ICollection<UserChestState> UserStates { get; set; } = [];
}
