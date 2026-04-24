using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;

namespace LifeLevel.Modules.WorldZone.Application.UseCases;

/// <summary>
/// One-shot chest opening. A chest zone can only be opened once per user:
/// once the <see cref="UserWorldChestState"/> row exists, re-opening throws
/// <see cref="ChestAlreadyOpenedException"/> which controllers translate
/// to 409 Conflict. Opening awards the zone's inline <c>ChestRewardXp</c>
/// via the Character module's XP port.
/// </summary>
public class WorldChestService(DbContext db, ICharacterXpPort characterXp)
{
    public async Task<OpenChestResult> OpenAsync(
        Guid userId,
        Guid zoneId,
        CancellationToken ct = default)
    {
        var zone = await db.Set<WorldZoneEntity>().FindAsync([zoneId], ct)
            ?? throw new InvalidOperationException("Zone not found.");

        if (zone.Type != WorldZoneType.Chest)
            throw new InvalidOperationException("Zone is not a chest.");

        // Must be at the chest zone to open it. Using CurrentZoneId — we
        // intentionally ignore destination so the user arrives first.
        var progress = await db.Set<UserWorldProgressEntity>()
            .FirstOrDefaultAsync(p => p.UserId == userId, ct)
            ?? throw new InvalidOperationException("Travel to the chest first.");

        if (progress.CurrentZoneId != zoneId)
            throw new InvalidOperationException("Travel to the chest first.");

        // Reject re-open. The unique index on (UserId, WorldZoneId) is the
        // DB-level safety net; this check produces a clean business error.
        var existing = await db.Set<UserWorldChestState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.WorldZoneId == zoneId, ct);
        if (existing != null)
            throw new ChestAlreadyOpenedException($"{zone.Name} has already been opened.");

        db.Set<UserWorldChestState>().Add(new UserWorldChestState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldZoneId = zoneId,
            OpenedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync(ct);

        int xp = zone.ChestRewardXp ?? 0;
        if (xp > 0)
        {
            await characterXp.AwardXpAsync(
                userId, "ChestReward", "🎁", $"Opened {zone.Name}", xp, ct);
        }

        return new OpenChestResult(zone.Id, zone.Name, xp);
    }
}
