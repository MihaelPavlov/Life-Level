using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Api.Application.BackgroundJobs;

/// <summary>
/// Periodically closes any Active season past its EndsAt (auto-granting reached-but-unclaimed
/// tiers) and promotes the next Scheduled season. Mirrors <see cref="GuildRaidExpiryJob"/>.
/// </summary>
public class SeasonRolloverJob(
    IServiceScopeFactory scopeFactory,
    ILogger<SeasonRolloverJob> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(10);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("SeasonRolloverJob started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var rollover = scope.ServiceProvider.GetRequiredService<ISeasonRolloverPort>();
                var closed = await rollover.RolloverDueSeasonsAsync(stoppingToken);
                if (closed > 0)
                    logger.LogInformation("Rolled over {Count} season(s).", closed);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "SeasonRolloverJob encountered an error.");
            }

            await Task.Delay(Interval, stoppingToken);
        }

        logger.LogInformation("SeasonRolloverJob stopped.");
    }
}
