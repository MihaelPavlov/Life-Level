using LifeLevel.Modules.Identity.Domain.Enums;

namespace LifeLevel.Modules.Identity.Domain.Entities;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public UserRole Role { get; set; } = UserRole.Player;

    public ICollection<UserRingItem> RingItems { get; set; } = [];
}
