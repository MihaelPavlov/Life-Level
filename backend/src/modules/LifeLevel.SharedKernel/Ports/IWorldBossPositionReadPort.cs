namespace LifeLevel.SharedKernel.Ports;

public sealed record WorldBossPosition(Guid ZoneId, DateTime ArrivedAt);

/// <summary>The boss zone occupied before a workout moves the player.</summary>
public interface IWorldBossPositionReadPort
{
    Task<WorldBossPosition?> GetCurrentBossZoneAsync(Guid userId, CancellationToken ct = default);
}
