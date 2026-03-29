using LifeLevel.Api.Application.Services;
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

                var streakService = scope.ServiceProvider.GetRequiredService<StreakService>();
                await streakService.CheckAndBreakExpiredStreaksAsync();

                var loginRewardService = scope.ServiceProvider.GetRequiredService<LoginRewardService>();
                await loginRewardService.ResetDailyClaimFlagsAsync();

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
