using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Domain.Entities;

public class Chest
{
    public Guid Id { get; set; }
    public Guid NodeId { get; set; }
    public MapNode Node { get; set; } = null!;
    public ChestRarity Rarity { get; set; }
    public int RewardXp { get; set; }

    public ICollection<UserChestState> UserStates { get; set; } = [];
}
