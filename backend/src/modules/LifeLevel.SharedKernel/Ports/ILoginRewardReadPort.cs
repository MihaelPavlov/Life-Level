namespace LifeLevel.SharedKernel.Ports;

public interface ILoginRewardReadPort
{
    Task<bool> HasClaimedTodayAsync(Guid userId, CancellationToken ct = default);
}
