namespace LifeLevel.Api.Domain.Entities;

public class Crossroads
{
    public Guid Id { get; set; }
    public Guid NodeId { get; set; }
    public MapNode Node { get; set; } = null!;

    public ICollection<CrossroadsPath> Paths { get; set; } = [];
    public ICollection<UserCrossroadsState> UserStates { get; set; } = [];
}
