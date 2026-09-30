using LifeLevel.Modules.Modes.Application.UseCases;

namespace LifeLevel.Api.Application.BackgroundJobs;

public class ModesExpiryJob(IServiceScopeFactory scopes, ILogger<ModesExpiryJob> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = scopes.CreateScope();
                await scope.ServiceProvider.GetRequiredService<ModesService>()
                    .ReconcileExpiredAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { }
            catch (Exception ex) { logger.LogError(ex, "Failed to reconcile expired mode runs."); }
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}
