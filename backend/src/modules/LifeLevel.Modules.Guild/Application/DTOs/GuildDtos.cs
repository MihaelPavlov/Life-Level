namespace LifeLevel.Modules.Guild.Application.DTOs;

public record GuildCreateRequest(string Name, string? Description, string? Icon);
public record GuildUpdateRequest(string Name, string? Description, string? Icon);
public record GuildRoleUpdateRequest(string Role);
public record GuildSearchItemDto(Guid Id, string Name, string Description, string Icon, int MemberCount, int MaxMembers, bool IsOpen);
public record GuildMemberDto(Guid UserId, string Username, string AvatarEmoji, string Role, DateTime JoinedAt, int RaidDamage);
public record GuildRaidContributionDto(
    Guid UserId,
    string Username,
    string AvatarEmoji,
    int DamageDealt,
    DateTime? LastActivityAt,
    int Rank,
    bool IsMvp);
public record GuildRaidBossDto(Guid Id, string Name, string Icon, int MaxHp, int RewardXp, int TimerDays, bool IsMini);
public record GuildRaidDto(
    Guid Id,
    Guid BossId,
    string BossName,
    string BossIcon,
    int MaxHp,
    int BaseMaxHp,
    int RewardXp,
    int BaseRewardXp,
    int GuildSizeAtStart,
    DateTime StartedAt,
    DateTime ExpiresAt,
    int TotalDamage,
    bool IsDefeated,
    bool IsExpired,
    DateTime? DefeatedAt,
    DateTime? RewardClaimedAt,
    bool RewardClaimed,
    Guid? MvpUserId,
    string? MvpUsername,
    int MvpDamage,
    int MvpBonusXp,
    IReadOnlyList<GuildRaidContributionDto> Contributions);

public record GuildDetailDto(
    Guid Id,
    string Name,
    string Description,
    string Icon,
    int MemberCount,
    int MaxMembers,
    bool IsOpen,
    bool IsLeader,
    string ViewerRole,
    bool CanManageRaid,
    bool CanManageMembers,
    bool CanEditGuild,
    IReadOnlyList<GuildMemberDto> Members,
    GuildRaidDto? ActiveRaid);

public record GuildStartRaidRequest(Guid BossId);
public record GuildDebugDamageRequest(int Damage);
public record GuildRaidVictoryAckRequest(Guid GuildRaidId);
public record GuildRaidExpiryAckRequest(Guid GuildRaidId);
