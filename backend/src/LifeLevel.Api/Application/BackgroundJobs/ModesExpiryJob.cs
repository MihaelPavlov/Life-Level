using LifeLevel.Modules.Modes.Application.UseCases;

namespace LifeLevel.Api.Application.BackgroundJobs;

public class ModesExpiryJob(IServiceScopeFactory scopes, PostgresJobLock jobLock,
    ILogger<ModesExpiryJob> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await jobLock.TryRunAsync(81004, async () =>
                {
                    using var scope = scopes.CreateScope();
                    await scope.ServiceProvider.GetRequiredService<ModesService>()
                        .ReconcileExpiredAsync(stoppingToken);
                }, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { }
            catch (Exception ex) { logger.LogError(ex, "Failed to reconcile expired mode runs."); }
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}
