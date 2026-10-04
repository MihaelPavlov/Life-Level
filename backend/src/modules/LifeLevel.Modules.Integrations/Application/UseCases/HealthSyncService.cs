using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Integrations.Application.UseCases;

public class HealthSyncService(
    DbContext db,
    ICharacterIdReadPort characterIdRead,
    IActivityLogPort activityLog,
    IActivityExternalIdReadPort activityExternalIdRead)
{
    public async Task<SyncResult> SyncBatchAsync(Guid userId, SyncBatchRequest request, CancellationToken ct = default)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
        if (characterId == null)
            return new SyncResult { Errors = ["Character not found for this user."] };

        int imported = 0, skipped = 0;
        var errors = new List<string>();

        foreach (var dto in request.Activities)
        {
            var one = await ImportOneAsync(userId, characterId.Value, dto, ct);
            if (one.Error is not null) errors.Add(one.Error);
            else if (one.Result is not null) imported++;
            else skipped++;
        }

        return new SyncResult { Imported = imported, Skipped = skipped, Errors = errors };
    }

    /// <summary>
    /// Imports a single external workout into the game with the same dedupe as
    /// <see cref="SyncBatchAsync"/>. Result is null when it was already imported
    /// (skipped); Error is set when processing failed.
    /// </summary>
    public async Task<(ActivityLogPortResult? Result, string? Error)> ImportOneAsync(
        Guid userId, Guid characterId, ExternalActivityDto dto, CancellationToken ct = default)
    {
        try
        {
            // Check whether this external activity was already successfully processed.
            // The unique index on ExternalActivityRecord is (CharacterId, Provider, ExternalId).
            // We only skip if WasImported = true. A record with WasImported = false means a
            // previous attempt saved the dedup row but crashed before finishing — retry it.
            var existing = await db.Set<ExternalActivityRecord>()
                .FirstOrDefaultAsync(r =>
                    r.CharacterId == characterId &&
                    r.Provider    == dto.Provider &&
                    r.ExternalId  == dto.ExternalId, ct);

            if (existing?.WasImported == true)
                return (null, null);

            // The activity can have been saved before the final dedup flag was
            // written. Retrying the log in that state violates Activities' unique
            // external-ID index and leaves the pending workout claimable forever.
            var savedActivityId = await activityExternalIdRead
                .FindActivityIdByExternalIdAsync(characterId, dto.ExternalId, ct);
            if (savedActivityId is not null)
            {
                var recordToRepair = existing ?? new ExternalActivityRecord
                {
                    Id = Guid.NewGuid(),
                    CharacterId = characterId,
                    Provider = dto.Provider,
                    ExternalId = dto.ExternalId,
                    ActivityStartTime = dto.PerformedAt,
                };
                if (existing is null) db.Set<ExternalActivityRecord>().Add(recordToRepair);
                recordToRepair.WasImported = true;
                recordToRepair.ImportedActivityId = savedActivityId;
                recordToRepair.SyncedAt = DateTime.UtcNow;
                await db.SaveChangesAsync(ct);
                return (null, null);
            }

            if (!Enum.TryParse<ActivityType>(dto.ActivityType, ignoreCase: true, out var activityType))
                activityType = ActivityType.Gym;

            // Reuse a stuck (WasImported=false) record or insert a new dedup sentinel.
            // Saving this before calling LogExternalActivityAsync prevents a second concurrent
            // webhook delivery from racing past the dedup check and double-importing.
            ExternalActivityRecord record;
            if (existing is not null)
            {
                // Previous attempt left a stuck record; update its timestamp and retry.
                record = existing;
                record.SyncedAt = DateTime.UtcNow;
                await db.SaveChangesAsync(ct);
            }
            else
            {
                record = new ExternalActivityRecord
                {
                    Id = Guid.NewGuid(),
                    CharacterId = characterId,
                    Provider = dto.Provider,
                    ExternalId = dto.ExternalId,
                    ActivityStartTime = dto.PerformedAt,
                    WasImported = false,
                    SyncedAt = DateTime.UtcNow,
                };
                db.Set<ExternalActivityRecord>().Add(record);
                await db.SaveChangesAsync(ct);
            }

            var result = await activityLog.LogExternalActivityAsync(
                userId, activityType, dto.DurationMinutes,
                dto.DistanceKm, dto.Calories, dto.HeartRateAvg,
                dto.ExternalId, dto.PerformedAt, ct);

            record.WasImported = true;
            record.ImportedActivityId = result.ActivityId;
            await db.SaveChangesAsync(ct);

            return (result, null);
        }
        catch (Exception ex)
        {
            return (null, $"{dto.ExternalId}: {ex.Message}");
        }
    }

    /// <summary>
    /// Onboarding history import. Same dedupe as <see cref="SyncBatchAsync"/>,
    /// but each workout goes through the history path (half XP, no XP award,
    /// no quests/bosses/events). Step-count walks are not workouts and are skipped.
    /// </summary>
    public async Task<(SyncResult Result, List<HistoricalActivityResult> Workouts)> ImportHistoryAsync(
        Guid userId, IEnumerable<ExternalActivityDto> activities, CancellationToken ct = default)
    {
        var workouts = new List<HistoricalActivityResult>();
        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
        if (characterId == null)
            return (new SyncResult { Errors = ["Character not found for this user."] }, workouts);

        int skipped = 0;
        var errors = new List<string>();
        foreach (var dto in activities)
        {
            if (dto.ExternalId.Contains(":steps:", StringComparison.Ordinal) || dto.DurationMinutes <= 0)
            {
                skipped++;
                continue;
            }
            try
            {
                var existing = await db.Set<ExternalActivityRecord>()
                    .FirstOrDefaultAsync(r =>
                        r.CharacterId == characterId &&
                        r.Provider    == dto.Provider &&
                        r.ExternalId  == dto.ExternalId, ct);
                if (existing?.WasImported == true)
                {
                    skipped++;
                    continue;
                }

                if (!Enum.TryParse<ActivityType>(dto.ActivityType, ignoreCase: true, out var activityType))
                    activityType = ActivityType.Gym;

                var record = existing ?? new ExternalActivityRecord
                {
                    Id = Guid.NewGuid(),
                    CharacterId = characterId.Value,
                    Provider = dto.Provider,
                    ExternalId = dto.ExternalId,
                    ActivityStartTime = dto.PerformedAt,
                    WasImported = false,
                };
                record.SyncedAt = DateTime.UtcNow;
                if (existing is null) db.Set<ExternalActivityRecord>().Add(record);
                await db.SaveChangesAsync(ct);

                var result = await activityLog.ImportHistoricalActivityAsync(
                    userId, activityType, dto.DurationMinutes,
                    dto.DistanceKm, dto.Calories, dto.HeartRateAvg,
                    dto.ExternalId, dto.PerformedAt, ct);

                record.WasImported = true;
                record.ImportedActivityId = result.ActivityId;
                await db.SaveChangesAsync(ct);
                workouts.Add(result);
            }
            catch (Exception ex)
            {
                errors.Add($"{dto.ExternalId}: {ex.Message}");
            }
        }

        return (new SyncResult { Imported = workouts.Count, Skipped = skipped, Errors = errors }, workouts);
    }

    public async Task<SyncResult> ImportSingleAsync(Guid userId, ExternalActivityDto dto, CancellationToken ct = default)
    {
        return await SyncBatchAsync(userId, new SyncBatchRequest { Activities = [dto] }, ct);
    }

    /// <summary>
    /// Reprocesses all ExternalActivityRecords for a user that have WasImported = false.
    /// These are records where the dedup sentinel was written but the game processing
    /// (XP / stats / quests) never completed successfully.
    ///
    /// Handles the torn-write case: if an Activity row already exists for the same ExternalId
    /// (meaning the Activity was saved but the final WasImported flag update failed), we
    /// repair the ExternalActivityRecord in-place rather than re-running the full pipeline
    /// and double-awarding XP.
    /// </summary>
    public async Task<SyncResult> ReprocessStuckAsync(Guid userId, CancellationToken ct = default)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
        if (characterId == null)
            return new SyncResult { Errors = ["Character not found for this user."] };

        var stuckRecords = await db.Set<ExternalActivityRecord>()
            .Where(r => r.CharacterId == characterId && !r.WasImported)
            .ToListAsync(ct);

        if (stuckRecords.Count == 0)
            return new SyncResult();

        int imported = 0, skipped = 0;
        var errors = new List<string>();

        foreach (var record in stuckRecords)
        {
            try
            {
                // Check if the Activity row already exists for this ExternalId (torn-write case:
                // Activity was saved but the WasImported flag update failed after it).
                var existingActivityId = await activityExternalIdRead
                    .FindActivityIdByExternalIdAsync(characterId.Value, record.ExternalId, ct);

                if (existingActivityId is not null)
                {
                    // Torn write: Activity was already saved and XP/stats were awarded.
                    // Just repair the flag so this record stops showing up as stuck.
                    record.WasImported = true;
                    record.ImportedActivityId = existingActivityId;
                    await db.SaveChangesAsync(ct);
                    skipped++;
                    continue;
                }

                // True stuck record: Activity was never created. Re-run the full pipeline.
                // We cannot reconstruct the original activity type or duration from the record alone
                // since ExternalActivityRecord only stores Provider, ExternalId, and ActivityStartTime.
                // These fields are not enough to re-derive the game stats without re-fetching from
                // the provider, so we report this as an error that requires a fresh sync from the client.
                errors.Add($"{record.ExternalId}: Activity data unavailable for reprocessing — " +
                           $"please trigger a fresh sync from the {record.Provider} connection.");
            }
            catch (Exception ex)
            {
                errors.Add($"{record.ExternalId}: {ex.Message}");
            }
        }

        return new SyncResult { Imported = imported, Skipped = skipped, Errors = errors };
    }
}
