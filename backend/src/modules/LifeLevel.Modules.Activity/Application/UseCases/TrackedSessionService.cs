using LifeLevel.Modules.Activity.Application.DTOs;
using LifeLevel.Modules.Activity.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Activity.Application.UseCases;

public sealed class TrackedSessionService(
    DbContext db,
    ICharacterIdReadPort characterIds,
    ActivityService activities)
{
    public async Task<TrackedSessionDto> FinishAsync(Guid userId, FinishTrackedSessionRequest request, CancellationToken ct)
    {
        if (request.SessionId == Guid.Empty || !Enum.IsDefined(request.Type) ||
            request.StartedAtUtc.Kind != DateTimeKind.Utc || request.EndedAtUtc.Kind != DateTimeKind.Utc ||
            request.EndedAtUtc <= request.StartedAtUtc || request.EndedAtUtc > DateTime.UtcNow.AddMinutes(5) ||
            request.StartedAtUtc < DateTime.UtcNow.AddDays(-30) ||
            request.ActiveSeconds < 1 || request.ActiveSeconds > 86400 ||
            request.ActiveSeconds > (request.EndedAtUtc - request.StartedAtUtc).TotalSeconds + 5 ||
            !double.IsFinite(request.DistanceMeters) || request.DistanceMeters < 0 ||
            request.DistanceMeters > request.ActiveSeconds * 25 ||
            request.GpsSampleCount < 0 || request.GpsCoveredSeconds < 0 ||
            request.GpsCoveredSeconds > request.ActiveSeconds + 30)
            throw new InvalidOperationException("Invalid tracked session.");

        var existing = await db.Set<TrackedSession>().AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == request.SessionId && x.UserId == userId, ct);
        if (existing is not null) return ToDto(existing, null);

        var characterId = await characterIds.GetCharacterIdAsync(userId, ct)
            ?? throw new InvalidOperationException("Character not found.");
        var outdoor = request.Type is ActivityType.Running or ActivityType.Walking or
            ActivityType.Hiking or ActivityType.Cycling;
        var gpsMeasured = outdoor && request.GpsSampleCount >= 2 &&
            request.DistanceMeters >= 100 && request.ActiveSeconds >= 120 &&
            request.GpsCoveredSeconds >= request.ActiveSeconds / 2;
        var session = new TrackedSession
        {
            Id = request.SessionId,
            UserId = userId,
            CharacterId = characterId,
            Type = request.Type,
            StartedAtUtc = request.StartedAtUtc,
            EndedAtUtc = request.EndedAtUtc,
            ActiveSeconds = request.ActiveSeconds,
            DistanceMeters = outdoor ? request.DistanceMeters : 0,
            GpsSampleCount = outdoor ? request.GpsSampleCount : 0,
            GpsMeasured = gpsMeasured,
        };
        // Rewarding a workout touches several tables. Keep the session and its
        // reward in one database transaction so a failed grant can be retried.
        await using var transaction = db.Database.ProviderName != "Microsoft.EntityFrameworkCore.InMemory"
            ? await db.Database.BeginTransactionAsync(ct)
            : null;
        db.Set<TrackedSession>().Add(session);
        await db.SaveChangesAsync(ct);

        LogActivityResult? reward = null;
        if (gpsMeasured)
        {
            reward = await activities.LogActivityAsync(userId, new LogActivityRequest
            {
                Type = request.Type,
                DurationMinutes = Math.Max(1, (int)Math.Round(request.ActiveSeconds / 60.0)),
                DistanceKm = request.DistanceMeters / 1000.0,
            });
            session.RewardedActivityId = reward.ActivityId;
            await db.SaveChangesAsync(ct);
        }
        if (transaction is not null) await transaction.CommitAsync(ct);
        return ToDto(session, reward);
    }

    public async Task<IReadOnlyList<TrackedSessionDto>> GetHistoryAsync(Guid userId, CancellationToken ct)
    {
        var rows = await db.Set<TrackedSession>().AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.EndedAtUtc)
            .Take(100)
            .ToListAsync(ct);
        return rows.Select(x => ToDto(x, null)).ToList();
    }

    private static TrackedSessionDto ToDto(TrackedSession session, LogActivityResult? reward) =>
        new(session.Id, session.Type, session.StartedAtUtc, session.EndedAtUtc,
            session.ActiveSeconds, session.DistanceMeters, session.GpsMeasured,
            session.RewardedActivityId, reward);
}
