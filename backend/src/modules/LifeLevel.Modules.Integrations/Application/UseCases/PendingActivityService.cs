using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Integrations.Application.UseCases;

/// <summary>
/// The pending-workout queue. Providers report workouts here instead of awarding
/// XP straight away; the player reviews and imports them from Home.
///
/// Webhook → fetch the activity once → <see cref="EnqueueAsync"/>.
/// Phone reads Health Connect / Apple Health locally → <see cref="StageAsync"/>.
/// Background checks read <see cref="ListAsync"/>; manual checks may first
/// fetch recent Strava workouts into this queue.
/// Player taps Import → <see cref="ImportAsync"/> (stored payload, no provider call).
/// </summary>
public class PendingActivityService(
    DbContext db,
    ICharacterIdReadPort characterIdRead,
    HealthSyncService healthSync,
    IActivityGainPreviewPort gainPreview,
    INotificationPort notifications,
    IActivityExternalIdReadPort activityExternalIdRead)
{
    /// <summary>Two workouts from different providers starting this close are the same workout.</summary>
    public static readonly TimeSpan DuplicateWindow = TimeSpan.FromMinutes(10);

    /// <summary>Duplicates are shown in the review sheet for this long, then hidden.</summary>
    public static readonly TimeSpan DuplicateVisibleFor = TimeSpan.FromDays(3);

    /// <summary>
    /// Adds a workout to the queue. Returns true when a new pending (not duplicate)
    /// row was created. Already-imported workouts and repeats are ignored; a pending
    /// row that has not been imported yet is refreshed with the latest payload.
    /// </summary>
    public async Task<bool> EnqueueAsync(Guid userId, ExternalActivityDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.ExternalId) || dto.DurationMinutes <= 0) return false;

        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
        if (characterId is null) return false;

        var importedActivityId = await activityExternalIdRead
            .FindActivityIdByExternalIdAsync(characterId.Value, dto.ExternalId, ct);
        var alreadyImported = importedActivityId is not null || await db.Set<ExternalActivityRecord>().AnyAsync(r =>
            r.CharacterId == characterId && r.Provider == dto.Provider &&
            r.ExternalId == dto.ExternalId && r.WasImported, ct);
        if (alreadyImported)
        {
            var stale = await db.Set<PendingActivity>().FirstOrDefaultAsync(p =>
                p.UserId == userId && p.Provider == dto.Provider &&
                p.ExternalId == dto.ExternalId && p.Status == PendingActivityStatus.Pending, ct);
            if (stale is not null)
            {
                stale.Status = PendingActivityStatus.Imported;
                stale.ImportedAt = DateTime.UtcNow;
                stale.ImportedActivityId = importedActivityId;
                await db.SaveChangesAsync(ct);
            }
            return false;
        }

        var existing = await db.Set<PendingActivity>().FirstOrDefaultAsync(p =>
            p.UserId == userId && p.Provider == dto.Provider && p.ExternalId == dto.ExternalId, ct);
        if (existing is not null)
        {
            if (existing.Status == PendingActivityStatus.Pending)
            {
                Apply(existing, dto);
                await db.SaveChangesAsync(ct);
            }
            return false;
        }

        var row = new PendingActivity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Provider = dto.Provider,
            ExternalId = dto.ExternalId,
            CreatedAt = DateTime.UtcNow,
            Status = PendingActivityStatus.Pending,
        };
        Apply(row, dto);

        var original = await FindOriginalAsync(userId, characterId.Value, row, ct);
        if (original is not null)
        {
            row.Status = PendingActivityStatus.Duplicate;
            row.DuplicateOfId = original.Value;
        }

        db.Set<PendingActivity>().Add(row);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // A concurrent webhook delivery inserted the same workout first.
            db.Entry(row).State = EntityState.Detached;
            return false;
        }
        return row.Status == PendingActivityStatus.Pending;
    }

    /// <summary>
    /// Queues workouts the phone read from Health Connect / Apple Health and
    /// returns the queue. Step-count walks are only accepted for finished days,
    /// because today's count keeps growing.
    /// </summary>
    public async Task<PendingActivityListDto> StageAsync(Guid userId, StagePendingRequest request, CancellationToken ct = default)
    {
        var todayStart = DateTime.UtcNow.Date;
        foreach (var dto in request.Activities)
        {
            if (dto.ExternalId.Contains(":steps:", StringComparison.Ordinal) && dto.PerformedAt >= todayStart)
                continue;
            await EnqueueAsync(userId, dto, ct);
        }
        return await ListAsync(userId, ct);
    }

    public async Task<PendingActivityListDto> ListAsync(Guid userId, CancellationToken ct = default)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
        var dupSince = DateTime.UtcNow - DuplicateVisibleFor;
        var rows = await db.Set<PendingActivity>()
            .Where(p => p.UserId == userId &&
                (p.Status == PendingActivityStatus.Pending ||
                 (p.Status == PendingActivityStatus.Duplicate && p.CreatedAt >= dupSince)))
            .OrderByDescending(p => p.PerformedAt)
            .ToListAsync(ct);

        // A workout may have been imported by another path, or the final sync
        // flag may have failed after Activities was saved. Clear those stale
        // queue rows before presenting the review sheet.
        if (characterId is not null)
        {
            var changed = false;
            foreach (var row in rows.Where(r => r.Status == PendingActivityStatus.Pending))
            {
                var activityId = await activityExternalIdRead
                    .FindActivityIdByExternalIdAsync(characterId.Value, row.ExternalId, ct);
                var imported = activityId is not null || await db.Set<ExternalActivityRecord>().AnyAsync(r =>
                    r.CharacterId == characterId && r.Provider == row.Provider &&
                    r.ExternalId == row.ExternalId && r.WasImported, ct);
                if (!imported) continue;
                row.Status = PendingActivityStatus.Imported;
                row.ImportedAt = DateTime.UtcNow;
                row.ImportedActivityId = activityId;
                changed = true;
            }
            if (changed)
            {
                await db.SaveChangesAsync(ct);
                rows.RemoveAll(r => r.Status == PendingActivityStatus.Imported);
            }
        }

        var originalIds = rows.Where(r => r.DuplicateOfId != null).Select(r => r.DuplicateOfId!.Value).ToList();
        var originals = originalIds.Count == 0
            ? new Dictionary<Guid, string>()
            : await db.Set<PendingActivity>()
                .Where(p => originalIds.Contains(p.Id))
                .ToDictionaryAsync(p => p.Id, p => p.Provider, ct);

        var items = rows.Select(r =>
        {
            var dto = ToDto(r);
            if (r.DuplicateOfId is { } of && originals.TryGetValue(of, out var provider))
                dto.DuplicateOfProvider = provider;
            return dto;
        }).ToList();

        return new PendingActivityListDto
        {
            Items = items,
            PendingCount = items.Count(i => i.Status == "Pending"),
        };
    }

    /// <summary>
    /// Imports the selected pending workouts through the normal external-activity
    /// path (same dedupe, XP, quests, bosses, map distance). No provider call.
    /// Rows that are not pending any more are counted as skipped.
    /// </summary>
    public async Task<ImportPendingResult> ImportAsync(Guid userId, ImportPendingRequest request, CancellationToken ct = default)
    {
        var result = new ImportPendingResult();
        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
        if (characterId is null)
        {
            result.Errors.Add("Character not found for this user.");
            return result;
        }

        var ids = request.Ids.Distinct().ToList();
        var rows = await db.Set<PendingActivity>()
            .Where(p => p.UserId == userId && ids.Contains(p.Id))
            .OrderBy(p => p.PerformedAt)
            .ToListAsync(ct);
        result.Skipped += ids.Count - rows.Count;

        foreach (var row in rows)
        {
            if (row.Status != PendingActivityStatus.Pending)
            {
                result.Skipped++;
                continue;
            }

            var dto = new ExternalActivityDto
            {
                Provider = row.Provider,
                ExternalId = row.ExternalId,
                ActivityType = row.ActivityType,
                DurationMinutes = row.DurationMinutes,
                DistanceKm = row.DistanceKm,
                Calories = row.Calories,
                HeartRateAvg = row.HeartRateAvg,
                PerformedAt = row.PerformedAt,
            };
            var (logged, error) = await healthSync.ImportOneAsync(userId, characterId.Value, dto, ct);
            if (error is not null)
            {
                result.Errors.Add(error);
                continue;
            }

            row.Status = PendingActivityStatus.Imported;
            row.ImportedAt = DateTime.UtcNow;
            if (logged is null)
            {
                // Already imported through another path (e.g. the manual Strava sync).
                await db.SaveChangesAsync(ct);
                result.Skipped++;
                continue;
            }

            row.ImportedActivityId = logged.ActivityId;
            row.XpAwarded = logged.XpGained;
            await db.SaveChangesAsync(ct);

            var gains = Preview(row);
            result.Imported.Add(new ImportedPendingWorkoutDto
            {
                PendingId = row.Id,
                ActivityType = row.ActivityType,
                Provider = row.Provider,
                DistanceKm = row.DistanceKm,
                DurationMinutes = row.DurationMinutes,
                XpGained = logged.XpGained,
                Strength = gains.Strength,
                Endurance = gains.Endurance,
                Agility = gains.Agility,
                Flexibility = gains.Flexibility,
                Stamina = gains.Stamina,
            });
            result.TotalXp += logged.XpGained;
            result.TotalDistanceKm += row.DistanceKm ?? 0;
        }

        result.RemainingPending = await db.Set<PendingActivity>()
            .CountAsync(p => p.UserId == userId && p.Status == PendingActivityStatus.Pending, ct);
        return result;
    }

    /// <summary>
    /// One push per batch: sent when a webhook adds a workout and it is the only
    /// pending one, so a burst of uploads does not spam the player.
    /// </summary>
    public async Task NotifyIfFirstPendingAsync(Guid userId, CancellationToken ct = default)
    {
        var pending = await db.Set<PendingActivity>()
            .CountAsync(p => p.UserId == userId && p.Status == PendingActivityStatus.Pending, ct);
        if (pending != 1) return;
        try
        {
            await notifications.SendToUserAsync(
                userId,
                category: "workouts-pending",
                title: "New workout ready",
                body: "Pull down on Home to claim your XP.",
                data: new Dictionary<string, string> { ["deeplink"] = "lifelevel://home" },
                isCritical: false,
                ct: ct);
        }
        catch
        {
            // A failed push must never lose the workout.
        }
    }

    private static void Apply(PendingActivity row, ExternalActivityDto dto)
    {
        row.ActivityType = dto.ActivityType;
        row.DurationMinutes = dto.DurationMinutes;
        row.DistanceKm = dto.DistanceKm;
        row.Calories = dto.Calories;
        row.HeartRateAvg = dto.HeartRateAvg;
        row.PerformedAt = DateTime.SpecifyKind(dto.PerformedAt, DateTimeKind.Utc);
    }

    /// <summary>
    /// A workout from another provider that started within <see cref="DuplicateWindow"/>
    /// and lasted about as long is the same workout recorded twice (e.g. a run on
    /// a Garmin watch that also syncs to Strava).
    /// </summary>
    private async Task<Guid?> FindOriginalAsync(Guid userId, Guid characterId, PendingActivity row, CancellationToken ct)
    {
        var from = row.PerformedAt - DuplicateWindow;
        var to = row.PerformedAt + DuplicateWindow;

        var candidates = await db.Set<PendingActivity>()
            .Where(p => p.UserId == userId &&
                p.Provider != row.Provider &&
                p.Status != PendingActivityStatus.Duplicate &&
                p.PerformedAt >= from && p.PerformedAt <= to)
            .ToListAsync(ct);
        var match = candidates.FirstOrDefault(c => SimilarDuration(c.DurationMinutes, row.DurationMinutes));
        if (match is not null) return match.Id;

        // Imported before the queue existed (or through the manual Strava sync):
        // only the start time is stored, so a start-time match is enough.
        var importedElsewhere = await db.Set<ExternalActivityRecord>().AnyAsync(r =>
            r.CharacterId == characterId &&
            r.WasImported &&
            r.Provider != row.Provider &&
            !r.ExternalId.Contains(":steps:") &&
            r.ActivityStartTime >= from && r.ActivityStartTime <= to, ct);
        return importedElsewhere ? Guid.Empty : null;
    }

    private static bool SimilarDuration(int a, int b)
    {
        var longer = Math.Max(a, b);
        return longer == 0 || Math.Abs(a - b) <= Math.Max(3, longer * 0.25);
    }

    private ActivityGainPreview Preview(PendingActivity row)
    {
        if (!Enum.TryParse<ActivityType>(row.ActivityType, ignoreCase: true, out var type))
            type = ActivityType.Gym;
        return gainPreview.Preview(type, row.DurationMinutes, row.DistanceKm, row.Calories);
    }

    private PendingActivityDto ToDto(PendingActivity r)
    {
        var g = Preview(r);
        return new PendingActivityDto
        {
            Id = r.Id,
            Provider = r.Provider,
            ActivityType = r.ActivityType,
            DurationMinutes = r.DurationMinutes,
            DistanceKm = r.DistanceKm,
            Calories = r.Calories,
            PerformedAt = r.PerformedAt,
            Status = r.Status == PendingActivityStatus.Duplicate ? "Duplicate" : "Pending",
            PreviewXp = g.Xp,
            PreviewStrength = g.Strength,
            PreviewEndurance = g.Endurance,
            PreviewAgility = g.Agility,
            PreviewFlexibility = g.Flexibility,
            PreviewStamina = g.Stamina,
        };
    }
}
