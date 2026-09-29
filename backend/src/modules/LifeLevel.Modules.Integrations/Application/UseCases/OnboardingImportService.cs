using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Integrations.Application.UseCases;

/// <summary>
/// Onboarding "your past counts" import: turns a new player's last 30 days of
/// tracked workouts into XP and a starting level before they pick a class.
/// Only allowed until character setup completes.
/// </summary>
public class OnboardingImportService(
    HealthSyncService healthSync,
    StravaWebhookService strava,
    ICharacterInfoPort characterInfo,
    ICharacterXpPort characterXp)
{
    public const int WindowDays = 30;
    public const string SourceStrava = "strava";
    public const string SourceHealth = "health";

    public class SetupAlreadyCompleteException() : InvalidOperationException("History import is only available during onboarding.");

    public async Task<OnboardingPreviewResult> PreviewAsync(Guid userId, string source, CancellationToken ct = default)
    {
        if (!string.Equals(source, SourceStrava, StringComparison.OrdinalIgnoreCase))
            return new OnboardingPreviewResult(source, 0, ["Preview is only needed for server-side sources."]);

        var (activities, error) = await strava.FetchRecentAsync(userId, WindowDays, ct);
        return new OnboardingPreviewResult(
            SourceStrava,
            activities.Count(a => a.DurationMinutes > 0),
            error is null ? [] : [error]);
    }

    public async Task<OnboardingImportResult> ImportAsync(Guid userId, OnboardingImportRequest request, CancellationToken ct = default)
    {
        var info = await characterInfo.GetByUserIdAsync(userId, ct);
        if (info is null) throw new InvalidOperationException("Character not found.");
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
            if (error != null) errors.Add(error);
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

        var (result, workouts) = await healthSync.ImportHistoryAsync(userId, inWindow, ct);
        errors.AddRange(result.Errors);

        var totalXp = workouts.Sum(w => w.XpGained);
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
            TotalMinutes: workouts.Sum(w => w.DurationMinutes),
            TotalKm: Math.Round(workouts.Sum(w => w.DistanceKm), 1),
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
