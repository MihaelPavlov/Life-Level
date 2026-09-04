namespace LifeLevel.SharedKernel.Ports;

public record GuildRaidDefeatedInfo(
    Guid GuildId,
    Guid GuildRaidId,
    string BossName,
    string BossIcon,
    int RewardXp,
    int MvpBonusXp,
    string? TopContributorUsername,
    int TopContributorDamage,
    int YourDamage,
    int TotalDamage);

public record GuildRaidHpUpdatedInfo(
    Guid GuildId,
    Guid GuildRaidId,
    string BossName,
    string BossIcon,
    int MaxHp,
    int TotalDamage,
    int RemainingHp,
    Guid UserId,
    int DamageDelta,
    int UserTotalDamage);

public record GuildRaidExpiredInfo(
    Guid GuildId,
    Guid GuildRaidId,
    string BossName,
    string BossIcon,
    int MaxHp,
    int TotalDamage,
    int RemainingHp);

public record GuildRaidStartedInfo(
    Guid GuildId,
    Guid GuildRaidId,
    string BossName,
    string BossIcon,
    int MaxHp,
    int RewardXp,
    DateTime ExpiresAt);

public interface IGuildRaidRealtimePort
{
    Task RaidStartedAsync(GuildRaidStartedInfo info, CancellationToken ct = default);
    Task RaidHpUpdatedAsync(GuildRaidHpUpdatedInfo info, CancellationToken ct = default);
    Task RaidDefeatedAsync(GuildRaidDefeatedInfo info, CancellationToken ct = default);
    Task RaidExpiredAsync(GuildRaidExpiredInfo info, CancellationToken ct = default);
}

public sealed class NoOpGuildRaidRealtimePort : IGuildRaidRealtimePort
{
    public Task RaidStartedAsync(GuildRaidStartedInfo info, CancellationToken ct = default) => Task.CompletedTask;
    public Task RaidHpUpdatedAsync(GuildRaidHpUpdatedInfo info, CancellationToken ct = default) => Task.CompletedTask;
    public Task RaidDefeatedAsync(GuildRaidDefeatedInfo info, CancellationToken ct = default) => Task.CompletedTask;
    public Task RaidExpiredAsync(GuildRaidExpiredInfo info, CancellationToken ct = default) => Task.CompletedTask;
}

public interface IGuildRaidActivityPort
{
    Task<IReadOnlyList<GuildRaidDefeatedInfo>> ApplyActivityAsync(
        Guid userId,
        Guid activityId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        DateTime activityLoggedAt,
        CancellationToken ct = default);
}
