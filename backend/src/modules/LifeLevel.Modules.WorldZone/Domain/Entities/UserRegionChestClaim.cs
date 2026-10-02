namespace LifeLevel.Modules.WorldZone.Domain.Entities;

public class UserRegionChestClaim
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid RegionId { get; set; }
    public int Coins { get; set; }
    public int Gems { get; set; }
    public DateTime ClaimedAtUtc { get; set; }
}
