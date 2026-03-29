namespace LifeLevel.SharedKernel.Ports;

public interface ILoginRewardDailyReset
{
    Task ResetDailyClaimFlagsAsync(CancellationToken ct = default);
}
