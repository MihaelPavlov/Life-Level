using LifeLevel.Modules.Identity.Domain.Enums;

namespace LifeLevel.Modules.Identity.Domain.Entities;

public class UserRingItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public RingItemType ItemType { get; set; }
    public int SortOrder { get; set; }
}
