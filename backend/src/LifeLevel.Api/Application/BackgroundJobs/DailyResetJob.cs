using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.BackgroundJobs;

public sealed class DailyResetJob(
    IServiceScopeFactory scopeFactory,
    PostgresJobLock jobLock,
    ILogger<DailyResetJob> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await jobLock.TryRunAsync(81001, async () =>
                {
                    using var scope = scopeFactory.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                    var today = DateTime.UtcNow.Date;
                    if (await db.MaintenanceRuns.AnyAsync(x => x.Name == "daily-reset"
                        && x.CompletedForUtcDate == today, stoppingToken)) return;

                    await using var transaction = await db.Database.BeginTransactionAsync(stoppingToken);
                    var reset = scope.ServiceProvider.GetRequiredService<IStreakDailyReset>();
                    await reset.CheckAndBreakExpiredStreaksAsync(stoppingToken);
                    await reset.ResetShieldUsedTodayFlagsAsync(stoppingToken);
                    db.MaintenanceRuns.Add(new MaintenanceRun
                    {
                        Name = "daily-reset",
                        CompletedForUtcDate = today,
                        CompletedAtUtc = DateTime.UtcNow,
                    });
                    await db.SaveChangesAsync(stoppingToken);
                    await transaction.CommitAsync(stoppingToken);
                    logger.LogInformation("Daily reset completed for {Date} UTC.", today);
                }, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception ex) { logger.LogError(ex, "Daily reset failed; retrying."); }
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
        }
    }
}
