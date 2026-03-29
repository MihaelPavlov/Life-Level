namespace LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;

public class DungeonPortal
{
    public Guid Id { get; set; }
    public Guid NodeId { get; set; }
    // No MapNode nav prop — cross-module FK configured in AppDbContext
    public string Name { get; set; } = string.Empty;
    public int TotalFloors { get; set; }

    public ICollection<DungeonFloor> Floors { get; set; } = [];
    public ICollection<UserDungeonState> UserStates { get; set; } = [];
}
