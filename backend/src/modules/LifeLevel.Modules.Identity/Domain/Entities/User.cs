using LifeLevel.Modules.Identity.Domain.Enums;

namespace LifeLevel.Modules.Identity.Domain.Entities;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string NormalizedEmail { get; set; } = string.Empty;
    public string? PasswordHash { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public UserRole Role { get; set; } = UserRole.Player;

    /// <summary>
    /// True for accounts created through Google or Apple, which start with a
    /// generated name, until the player picks (or keeps) one.
    /// </summary>
    public bool NeedsUsername { get; set; }

    public ICollection<UserRingItem> RingItems { get; set; } = [];
    public ICollection<UserExternalLogin> ExternalLogins { get; set; } = [];
}
