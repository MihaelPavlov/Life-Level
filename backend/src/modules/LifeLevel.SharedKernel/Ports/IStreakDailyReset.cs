namespace LifeLevel.SharedKernel.Ports;

public interface IStreakDailyReset
{
    Task CheckAndBreakExpiredStreaksAsync(CancellationToken ct = default);
    Task ResetShieldUsedTodayFlagsAsync(CancellationToken ct = default);
}
