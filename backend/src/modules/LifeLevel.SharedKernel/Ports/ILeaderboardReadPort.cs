namespace LifeLevel.SharedKernel.Ports;

public enum LeaderboardScope { Global, Region, Guild }

public enum LeaderboardMetric { Power, Xp, Km, Boss, Streak }

/// <summary>One ranked player. <see cref="Score"/> is the chosen metric's value.</summary>
public record LeaderboardCandidate(
    Guid UserId, string Username, string? AvatarEmoji, int Level, string? ClassName, double Score);

/// <summary>
/// Everyone a scope contains, scored by one metric. <see cref="Available"/> is
/// false when the viewer has no such scope (no guild, no map position yet);
/// <see cref="ContextName"/> is the guild or region name.
/// </summary>
public record LeaderboardPool(bool Available, string? ContextName, IReadOnlyList<LeaderboardCandidate> Entries);

/// <summary>Reads leaderboard scores from the modules that own them.</summary>
public interface ILeaderboardReadPort
{
    Task<LeaderboardPool> GetPoolAsync(
        Guid viewerId, LeaderboardScope scope, LeaderboardMetric metric,
        DateTime weekStartUtc, CancellationToken ct = default);
}
