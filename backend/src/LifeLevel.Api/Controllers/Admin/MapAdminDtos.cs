using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Api.Controllers.Admin;

// --- Worlds -----------------------------------------------------------------

public record WorldSummaryDto(Guid Id, string Name, bool IsActive, DateTime CreatedAt, int RegionCount, int ZoneCount);

public record WorldDetailDto(
    Guid Id,
    string Name,
    bool IsActive,
    DateTime CreatedAt,
    IReadOnlyList<RegionSummaryDto> Regions);

public record CreateWorldRequest(string Name, bool IsActive);
public record UpdateWorldRequest(string Name, bool IsActive);

// --- Regions ----------------------------------------------------------------

public record RegionPinDto(string Label, string Value);

public record RegionSummaryDto(
    Guid Id,
    Guid WorldId,
    string Name,
    string Emoji,
    RegionTheme Theme,
    int ChapterIndex,
    int LevelRequirement,
    int ZoneCount);

public record RegionDetailDto(
    Guid Id,
    Guid WorldId,
    string Name,
    string Emoji,
    RegionTheme Theme,
    int ChapterIndex,
    int LevelRequirement,
    string Lore,
    string BossName,
    RegionBossStatus BossStatus,
    RegionStatus DefaultStatus,
    IReadOnlyList<RegionPinDto> Pins,
    IReadOnlyList<ZoneSummaryDto> Zones,
    IReadOnlyList<EdgeDto> Edges);

public record CreateRegionRequest(
    string Name,
    string Emoji,
    RegionTheme Theme,
    int ChapterIndex,
    int LevelRequirement,
    string Lore,
    string BossName,
    RegionBossStatus BossStatus,
    RegionStatus DefaultStatus,
    IReadOnlyList<RegionPinDto>? Pins);

public record UpdateRegionRequest(
    string Name,
    string Emoji,
    RegionTheme Theme,
    int ChapterIndex,
    int LevelRequirement,
    string Lore,
    string BossName,
    RegionBossStatus BossStatus,
    RegionStatus DefaultStatus,
    IReadOnlyList<RegionPinDto>? Pins);

// --- Zones ------------------------------------------------------------------

public record ZoneSummaryDto(
    Guid Id,
    Guid RegionId,
    string Name,
    string Emoji,
    WorldZoneType Type,
    int Tier,
    int LevelRequirement,
    int XpReward,
    double DistanceKm,
    bool IsStartZone,
    bool IsBoss,
    Guid? BranchOfId,
    int? ChestRewardXp,
    int? DungeonBonusXp,
    int? BossTimerDays,
    bool? BossSuppressExpiry,
    int FloorCount);

public record ZoneDetailDto(
    Guid Id,
    Guid RegionId,
    string Name,
    string? Description,
    string Emoji,
    WorldZoneType Type,
    int Tier,
    int LevelRequirement,
    int XpReward,
    double DistanceKm,
    bool IsStartZone,
    bool IsBoss,
    Guid? BranchOfId,
    int? LoreTotal,
    int? LoreCollected,
    int? NodesTotal,
    int? NodesCompleted,
    int? ChestRewardXp,
    string? ChestRewardDescription,
    int? DungeonBonusXp,
    int? BossTimerDays,
    bool? BossSuppressExpiry,
    IReadOnlyList<FloorDto> Floors);

public record CreateZoneRequest(
    string Name,
    string? Description,
    string Emoji,
    WorldZoneType Type,
    int Tier,
    int LevelRequirement,
    int XpReward,
    double DistanceKm,
    bool IsStartZone,
    Guid? BranchOfId,
    int? LoreTotal,
    int? NodesTotal,
    int? ChestRewardXp,
    string? ChestRewardDescription,
    int? DungeonBonusXp,
    int? BossTimerDays,
    bool? BossSuppressExpiry);

public record UpdateZoneRequest(
    string Name,
    string? Description,
    string Emoji,
    WorldZoneType Type,
    int Tier,
    int LevelRequirement,
    int XpReward,
    double DistanceKm,
    bool IsStartZone,
    Guid? BranchOfId,
    int? LoreTotal,
    int? NodesTotal,
    int? ChestRewardXp,
    string? ChestRewardDescription,
    int? DungeonBonusXp,
    int? BossTimerDays,
    bool? BossSuppressExpiry);

// --- Edges ------------------------------------------------------------------

public record EdgeDto(Guid Id, Guid FromZoneId, Guid ToZoneId, double DistanceKm, bool IsBidirectional);
public record CreateEdgeRequest(Guid FromZoneId, Guid ToZoneId, double DistanceKm, bool IsBidirectional);
public record UpdateEdgeRequest(double DistanceKm, bool IsBidirectional);

// --- Dungeon floors ---------------------------------------------------------

public record FloorDto(
    Guid Id,
    Guid WorldZoneId,
    int Ordinal,
    ActivityType ActivityType,
    DungeonFloorTargetKind TargetKind,
    double TargetValue,
    string Name,
    string Emoji);

public record CreateFloorRequest(
    int Ordinal,
    ActivityType ActivityType,
    DungeonFloorTargetKind TargetKind,
    double TargetValue,
    string Name,
    string Emoji);

public record UpdateFloorRequest(
    int Ordinal,
    ActivityType ActivityType,
    DungeonFloorTargetKind TargetKind,
    double TargetValue,
    string Name,
    string Emoji);

// --- Enum metadata ----------------------------------------------------------

public record EnumOption(int Value, string Name);

public record EnumsDto(
    IReadOnlyList<EnumOption> WorldZoneTypes,
    IReadOnlyList<EnumOption> RegionThemes,
    IReadOnlyList<EnumOption> RegionStatuses,
    IReadOnlyList<EnumOption> RegionBossStatuses,
    IReadOnlyList<EnumOption> ActivityTypes,
    IReadOnlyList<EnumOption> DungeonFloorTargetKinds);
