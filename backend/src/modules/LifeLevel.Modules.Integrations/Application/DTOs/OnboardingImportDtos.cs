namespace LifeLevel.Modules.Integrations.Application.DTOs;

/// <param name="Source">"strava" (server pulls the last 30 days) or "health" (client sends <see cref="Activities"/>).</param>
public class OnboardingImportRequest
{
    public string Source { get; set; } = string.Empty;
    public List<ExternalActivityDto> Activities { get; set; } = [];
}

public record ImportedWorkoutDto(
    string Type,
    DateTime PerformedAt,
    int DurationMinutes,
    double DistanceKm,
    long Xp);

public record OnboardingImportResult(
    string Source,
    int Imported,
    int Skipped,
    int TotalMinutes,
    double TotalKm,
    long TotalXp,
    bool LeveledUp,
    int PreviousLevel,
    int NewLevel,
    DateTime WindowStart,
    DateTime WindowEnd,
    IReadOnlyList<ImportedWorkoutDto> Workouts,
    IReadOnlyList<string> Errors);

public record OnboardingPreviewResult(string Source, int WorkoutCount, IReadOnlyList<string> Errors);
