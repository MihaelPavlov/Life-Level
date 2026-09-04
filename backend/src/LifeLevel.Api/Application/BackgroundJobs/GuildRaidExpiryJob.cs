using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Api.Application.BackgroundJobs;

public class GuildRaidExpiryJob(
    IServiceScopeFactory scopeFactory,
    ILogger<GuildRaidExpiryJob> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(5);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("GuildRaidExpiryJob started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var maintenance = scope.ServiceProvider.GetRequiredService<IGuildRaidMaintenancePort>();
                var expired = await maintenance.ExpireOverdueRaidsAsync(stoppingToken);
                if (expired > 0)
                {
                    logger.LogInformation("Expired {Count} overdue guild raids.", expired);
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "GuildRaidExpiryJob encountered an error.");
            }

            await Task.Delay(Interval, stoppingToken);
        }

        logger.LogInformation("GuildRaidExpiryJob stopped.");
    }
}
