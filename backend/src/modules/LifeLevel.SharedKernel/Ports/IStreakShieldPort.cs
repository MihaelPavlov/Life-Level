namespace LifeLevel.SharedKernel.Ports;

public interface IStreakShieldPort
{
    Task AddShieldAsync(Guid userId, CancellationToken ct = default);
}
