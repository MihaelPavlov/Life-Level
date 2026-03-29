namespace LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;

public class Crossroads
{
    public Guid Id { get; set; }
    public Guid NodeId { get; set; }
    // No MapNode nav prop — cross-module FK configured in AppDbContext

    public ICollection<CrossroadsPath> Paths { get; set; } = [];
    public ICollection<UserCrossroadsState> UserStates { get; set; } = [];
}
