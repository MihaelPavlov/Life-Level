namespace LifeLevel.Modules.WorldZone.Domain.Entities;

public class UserWorldProgress
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    // No User navigation property — cross-module FK configured in AppDbContext

    public Guid CurrentZoneId { get; set; }
    public WorldZone CurrentZone { get; set; } = null!;

    public Guid? CurrentEdgeId { get; set; }
    public WorldZoneEdge? CurrentEdge { get; set; }
    public double DistanceTraveledOnEdge { get; set; } = 0;

    /// Distance the user has banked but not yet applied to an edge — i.e. they
    /// logged a workout while standing still (no destination set, or stopped
    /// at a crossroads). Drained into edge progress on the next SetDestination
    /// or AddDistance call once an edge is active.
    public double PendingDistanceKm { get; set; } = 0;

    public Guid? DestinationZoneId { get; set; }
    public WorldZone? DestinationZone { get; set; }

    // Snapshot of the region containing CurrentZone, maintained by the service
    // whenever CurrentZoneId changes. Lets the map screen highlight "Active"
    // region without joining through WorldZone.
    public Guid? CurrentRegionId { get; set; }

    /// When non-null, a blocker encounter is blocking the player on the current edge.
    /// Progress is capped at the blocker's position until cleared.
    public Guid? ActiveBlockerEncounterId { get; set; }

    /// When non-null, a trail encounter is waiting for explicit player action.
    /// Used for merchants/stories so banked km cannot pass them implicitly.
    public Guid? ActiveTrailEncounterId { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Guid WorldId { get; set; }
    public World World { get; set; } = null!;

    public ICollection<UserZoneUnlock> UnlockedZones { get; set; } = [];
}
