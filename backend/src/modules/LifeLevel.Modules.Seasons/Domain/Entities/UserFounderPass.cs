using LifeLevel.Modules.Seasons.Domain.Enums;

namespace LifeLevel.Modules.Seasons.Domain.Entities;

/// <summary>
/// Entitlement row — its existence unlocks the Founder lane for (UserId, SeasonId).
/// Payment is out of scope; today it is created by the no-op "purchase" endpoint or by an admin.
/// </summary>
public class UserFounderPass
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public Guid SeasonId { get; set; }

    public DateTime AcquiredAt { get; set; } = DateTime.UtcNow;

    public FounderPassSource Source { get; set; } = FounderPassSource.Purchase;
}
