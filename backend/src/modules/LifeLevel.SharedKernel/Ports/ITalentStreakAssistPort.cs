namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Lets the Streak module ask the Talents module whether a missed day can be auto-saved by the
/// "Second Wind" talent (without spending a shield). Consumes one weekly charge on success.
/// </summary>
public interface ITalentStreakAssistPort
{
    Task<bool> TryConsumeSecondWindAsync(Guid userId, DateTime dayUtc, CancellationToken ct = default);
}
