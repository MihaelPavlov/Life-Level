using LifeLevel.Modules.Notifications.Application.Ports.Out;
using LifeLevel.Modules.Notifications.Domain.Entities;
using LifeLevel.Modules.Notifications.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Notifications.Infrastructure.Persistence.Repositories;

/// <summary>
/// EF Core adapter for <see cref="INotificationRepository"/>. Uses the shared
/// AppDbContext (injected as <see cref="DbContext"/>) per the module's persistence
/// strategy (see ARCHITECTURE.txt — single AppDbContext, per-module configurations).
/// </summary>
public class NotificationRepository(DbContext db) : INotificationRepository
{
    public Task<List<DeviceToken>> GetActiveTokensAsync(Guid userId, CancellationToken ct = default) =>
        db.Set<DeviceToken>()
            .Where(t => t.UserId == userId && t.IsActive)
            .ToListAsync(ct);

    public Task<DeviceToken?> FindTokenAsync(Guid userId, string token, CancellationToken ct = default) =>
        db.Set<DeviceToken>()
            .FirstOrDefaultAsync(t => t.UserId == userId && t.Token == token, ct);

    public Task<List<DeviceToken>> FindTokenAcrossUsersAsync(string token, CancellationToken ct = default) =>
        db.Set<DeviceToken>()
            .Where(t => t.Token == token)
            .ToListAsync(ct);

    public async Task AddTokenAsync(DeviceToken token, CancellationToken ct = default)
    {
        await db.Set<DeviceToken>().AddAsync(token, ct);
    }

    public Task<int> CountSentNonCriticalSinceAsync(Guid userId, DateTime sinceUtc, CancellationToken ct = default) =>
        db.Set<NotificationLog>()
            .CountAsync(l =>
                l.UserId == userId
                && l.SentAt >= sinceUtc
                && l.Outcome == NotificationOutcome.Sent
                && !l.IsCritical,
                ct);

    public async Task AddLogAsync(NotificationLog log, CancellationToken ct = default)
    {
        await db.Set<NotificationLog>().AddAsync(log, ct);
    }

    public Task SaveChangesAsync(CancellationToken ct = default) =>
        db.SaveChangesAsync(ct);
}
