using LifeLevel.Modules.Notifications.Domain.Enums;

namespace LifeLevel.Modules.Notifications.Domain.Entities;

/// <summary>
/// An FCM registration token for a specific device belonging to a user. Users can have
/// multiple tokens (e.g., phone + tablet). Tokens become inactive when FCM reports them
/// as unregistered (uninstall, app wipe) — see NotificationService + FcmNotificationAdapter.
/// </summary>
public class DeviceToken
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public string Token { get; set; } = null!;
    public DevicePlatform Platform { get; set; }
    public DateTime RegisteredAt { get; set; } = DateTime.UtcNow;
    public DateTime LastUsedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
}
