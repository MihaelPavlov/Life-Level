using LifeLevel.Modules.Notifications.Domain.Entities;

namespace LifeLevel.Modules.Notifications.Application.Ports.Out;

/// <summary>
/// Driven port for Notifications persistence: device tokens, the notification
/// audit log, and per-user preferences. Implemented by an EF Core adapter over
/// the shared AppDbContext (see ARCHITECTURE.txt — single AppDbContext, per-module
/// configurations).
/// </summary>
public interface INotificationRepository
{
    Task<List<DeviceToken>> GetActiveTokensAsync(Guid userId, CancellationToken ct = default);
    Task<DeviceToken?> FindTokenAsync(Guid userId, string token, CancellationToken ct = default);
    Task<List<DeviceToken>> FindTokenAcrossUsersAsync(string token, CancellationToken ct = default);
    Task AddTokenAsync(DeviceToken token, CancellationToken ct = default);

    Task<int> CountSentNonCriticalSinceAsync(Guid userId, DateTime sinceUtc, CancellationToken ct = default);
    Task AddLogAsync(NotificationLog log, CancellationToken ct = default);
    Task<List<NotificationLog>> GetForUserAsync(Guid userId, int limit, CancellationToken ct = default);
    Task MarkAllReadAsync(Guid userId, CancellationToken ct = default);

    Task<NotificationPreference?> GetPreferencesAsync(Guid userId, CancellationToken ct = default);
    Task AddPreferencesAsync(NotificationPreference preferences, CancellationToken ct = default);

    Task SaveChangesAsync(CancellationToken ct = default);
}
