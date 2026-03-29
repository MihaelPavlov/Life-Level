using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;

public class DungeonFloor
{
    public Guid Id { get; set; }
    public Guid DungeonPortalId { get; set; }
    public DungeonPortal DungeonPortal { get; set; } = null!;
    public int FloorNumber { get; set; }
    public ActivityType RequiredActivity { get; set; }
    public int RequiredMinutes { get; set; }
    public int RewardXp { get; set; }
}
