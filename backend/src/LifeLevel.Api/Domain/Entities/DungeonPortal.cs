namespace LifeLevel.Api.Domain.Entities;

public class DungeonPortal
{
    public Guid Id { get; set; }
    public Guid NodeId { get; set; }
    public MapNode Node { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public int TotalFloors { get; set; }

    public ICollection<DungeonFloor> Floors { get; set; } = [];
    public ICollection<UserDungeonState> UserStates { get; set; } = [];
}
