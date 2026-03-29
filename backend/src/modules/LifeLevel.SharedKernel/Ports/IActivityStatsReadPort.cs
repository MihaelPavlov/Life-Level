namespace LifeLevel.SharedKernel.Ports;

public record WeeklyActivityStatsDto(int WeeklyRuns, double WeeklyDistanceKm, long WeeklyXpEarned);

public interface IActivityStatsReadPort
{
    Task<WeeklyActivityStatsDto> GetWeeklyStatsAsync(Guid userId, CancellationToken ct = default);
}
