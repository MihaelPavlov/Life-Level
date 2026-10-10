using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using LifeLevel.SharedKernel.Abstractions;

namespace LifeLevel.Modules.Integrations.Application.UseCases;

/// <summary>
/// Onboarding "your past counts" import: turns a new player's last 30 days of
/// tracked workouts into XP and a starting level before they pick a class.
/// Only allowed until character setup completes.
/// </summary>
public class OnboardingImportService(
    HealthSyncService healthSync,
    StravaWebhookService strava,
    PendingActivityService pending,
    ICharacterInfoPort characterInfo,
    ICharacterXpPort characterXp)
{
    public const int WindowDays = 30;

    /// <summary>XP at the start of Level 3 (L(L−1)/2 × 300). Imports happen before setup, from 0 XP.</summary>
    public const long HistoryXpCap = 900;
    public const string SourceStrava = "strava";
    public const string SourceHealth = "health";

    public class SetupAlreadyCompleteException() : DomainException(
        "setup_already_complete", "History import is only available during onboarding.");
    public class StravaFetchException() : DomainException(
        "strava_sync_failed", "Could not reach Strava. Try again shortly.",
        DomainErrorKind.UpstreamUnavailable);

    public async Task<OnboardingPreviewResult> PreviewAsync(Guid userId, string source, CancellationToken ct = default)
    {
        if (!string.Equals(source, SourceStrava, StringComparison.OrdinalIgnoreCase))
            return new OnboardingPreviewResult(source, 0, 0, ["Preview is only needed for server-side sources."]);

        var (activities, error) = await strava.FetchRecentAsync(userId, WindowDays, ct);
        if (error is not null) throw new StravaFetchException();
        return new OnboardingPreviewResult(
            SourceStrava,
            activities.Count(a => a.DurationMinutes > 0 && a.RecordingMethod != ActivityRecordingMethod.Manual),
            activities.Count(a => a.DurationMinutes > 0 && a.RecordingMethod == ActivityRecordingMethod.Manual),
            []);
    }

    public async Task<OnboardingImportResult> ImportAsync(Guid userId, OnboardingImportRequest request, CancellationToken ct = default)
    {
        var info = await characterInfo.GetByUserIdAsync(userId, ct);
        if (info is null) throw new DomainException(
            "character_not_found", "Character not found.", DomainErrorKind.NotFound);
        if (info.IsSetupComplete) throw new SetupAlreadyCompleteException();

        var windowEnd = DateTime.UtcNow;
        var windowStart = windowEnd.AddDays(-WindowDays);
        var errors = new List<string>();

        List<ExternalActivityDto> activities;
        string source;
        if (string.Equals(request.Source, SourceStrava, StringComparison.OrdinalIgnoreCase))
        {
            source = SourceStrava;
            var (fetched, error) = await strava.FetchRecentAsync(userId, WindowDays, ct);
            if (error is not null) throw new StravaFetchException();
            activities = fetched;
        }
        else
        {
            source = SourceHealth;
            activities = request.Activities;
        }

        var inWindow = activities
            .Where(a => a.PerformedAt >= windowStart && a.PerformedAt <= windowEnd.AddMinutes(5))
            .OrderBy(a => a.PerformedAt)
            .ToList();

        var rejectedManual = inWindow
            .Where(a => a.RecordingMethod == ActivityRecordingMethod.Manual)
            .ToList();
        foreach (var rejected in rejectedManual)
            await pending.EnqueueAsync(userId, rejected, ct);
        // The onboarding result reports this count and is persisted by the client,
        // so these rows have completed their one-time visibility lifecycle.
        await pending.AcknowledgeRejectedExternalIdsAsync(
            userId, rejectedManual.Select(a => a.ExternalId), ct);

        var (result, workouts) = await healthSync.ImportHistoryAsync(userId, inWindow, ct);
        errors.AddRange(result.Errors);

        // The head start stops at Level 3; later features open one tier per workout after setup.
        var totalXp = Math.Min(workouts.Sum(w => w.XpGained), HistoryXpCap);
        var xp = XpAwardResult.None;
        if (totalXp > 0)
        {
            // One award for the whole history → one level-up receipt, which the
            // onboarding Level screen shows and acknowledges.
            xp = await characterXp.AwardXpAsync(
                userId, "HistoryImport", "📥",
                $"Your last {WindowDays} days · {workouts.Count} workout{(workouts.Count == 1 ? "" : "s")}",
                totalXp, ct);
        }

        return new OnboardingImportResult(
            Source: source,
            Imported: result.Imported,
            Skipped: result.Skipped,
            RejectedManualCount: rejectedManual.Count,
            TotalMinutes: workouts.Sum(w => w.DurationMinutes),
            TotalKm: Math.Round(workouts.Sum(w => w.DistanceKm), 1),
            TotalAdventureDistanceKm: Math.Round(workouts.Sum(w => w.AdventureDistanceKm), 2),
            TotalXp: totalXp,
            LeveledUp: xp.LeveledUp,
            PreviousLevel: xp.LeveledUp ? xp.PreviousLevel : 0,
            NewLevel: xp.LeveledUp ? xp.NewLevel : 0,
            WindowStart: windowStart,
            WindowEnd: windowEnd,
            Workouts: workouts
                .OrderByDescending(w => w.PerformedAt)
                .Select(w => new ImportedWorkoutDto(w.Type.ToString(), w.PerformedAt, w.DurationMinutes,
                    Math.Round(w.DistanceKm, 2), w.XpGained))
                .ToList(),
            Errors: errors);
    }
}
