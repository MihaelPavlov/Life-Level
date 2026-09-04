namespace LifeLevel.SharedKernel.Ports;

public interface IGuildRaidMaintenancePort
{
    Task<int> ExpireOverdueRaidsAsync(CancellationToken ct = default);
}
