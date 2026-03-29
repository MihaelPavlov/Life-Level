using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace LifeLevel.Api.Application.BackgroundJobs;

public class DailyResetJob(IServiceScopeFactory scopeFactory, ILogger<DailyResetJob> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("DailyResetJob started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            var now = DateTime.UtcNow;
            var nextMidnight = now.Date.AddDays(1);
            var delay = nextMidnight - now;

            logger.LogInformation("DailyResetJob sleeping until {NextMidnight} UTC ({Delay} remaining).", nextMidnight, delay);

            await Task.Delay(delay, stoppingToken);

            if (stoppingToken.IsCancellationRequested) break;

            logger.LogInformation("DailyResetJob running midnight reset.");

            try
            {
                using var scope = scopeFactory.CreateScope();
                var sp = scope.ServiceProvider;

                var streakReset = sp.GetRequiredService<IStreakDailyReset>();
                await streakReset.CheckAndBreakExpiredStreaksAsync(stoppingToken);
                await streakReset.ResetShieldUsedTodayFlagsAsync(stoppingToken);

                var loginReset = sp.GetRequiredService<ILoginRewardDailyReset>();
                await loginReset.ResetDailyClaimFlagsAsync(stoppingToken);

                logger.LogInformation("DailyResetJob completed successfully.");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "DailyResetJob encountered an error during midnight reset.");
            }
        }

        logger.LogInformation("DailyResetJob stopped.");
    }
}
