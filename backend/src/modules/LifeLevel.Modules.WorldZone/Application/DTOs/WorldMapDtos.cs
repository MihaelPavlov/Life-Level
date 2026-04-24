namespace LifeLevel.Modules.WorldZone.Application.DTOs;

// Canonical contracts for the v3 World Map (§12 of WORLD-MAP-FINAL-DESIGN.md).
// All status/theme fields serialize as lowercased enum names ("forest", "active",
// "locked", "defeated", "completed", "next", "available") — the mobile client keeps
// them as plain strings, so we skip enum roundtripping at the API boundary.

public record WorldMapDto(
    WorldUserDto User,
    ActiveJourneyDto? ActiveJourney,
    IReadOnlyList<RegionSummaryDto> Regions);

public record WorldUserDto(int Level, string CharacterName);

public record ActiveJourneyDto(
    string DestinationZoneName,
    string DestinationZoneEmoji,
    string RegionName,
    double DistanceTravelledKm,
    double DistanceTotalKm,
    int ArrivalXpReward,
    string? ArrivalBonusLabel);

public record RegionSummaryDto(
    Guid Id,
    string Name,
    string Emoji,
    string Theme,
    string Lore,
    int ChapterIndex,
    string Status,
    int LevelRequirement,
    int CompletedZones,
    int TotalZones,
    int TotalXpEarned,
    int? ZonesUntilBoss,
    string BossName,
    string BossStatus,
    IReadOnlyList<RegionPinDto> Pins);

public record RegionPinDto(string Label, string Value);

public record RegionDetailDto(
    Guid Id,
    string Name,
    string Emoji,
    string Theme,
    string Lore,
    int ChapterIndex,
    string Status,
    int LevelRequirement,
    int CompletedZones,
    int TotalZones,
    int TotalXpEarned,
    int? ZonesUntilBoss,
    string BossName,
    string BossStatus,
    IReadOnlyList<RegionPinDto> Pins,
    IReadOnlyList<ZoneNodeDto> Nodes,
    IReadOnlyList<ZoneEdgeDto> Edges,
    IReadOnlyList<PathChoiceDto> PathChoices);

public record ZoneNodeDto(
    Guid Id,
    string Name,
    string Emoji,
    int Tier,
    string Status,
    bool IsCrossroads,
    bool IsBoss,
    string Description,
    int LevelRequirement,
    double DistanceKm,
    int XpReward,
    int? NodesCompleted,
    int? NodesTotal,
    int? LoreCollected,
    int? LoreTotal,
    Guid? BranchOf,
    // Chest fields (populated only when the zone is a Chest)
    bool IsChest,
    int? ChestRewardXp,
    bool? ChestIsOpened,
    // Dungeon fields (populated only when the zone is a Dungeon)
    bool IsDungeon,
    int? DungeonFloorsTotal,
    int? DungeonFloorsCompleted,
    int? DungeonFloorsForfeited,
    string? DungeonStatus);

public record ZoneEdgeDto(Guid FromId, Guid ToId);

public record PathChoiceDto(Guid CrossroadsZoneId, Guid ChosenZoneId);

// Chest opening response.
public record OpenChestResult(Guid ZoneId, string ZoneName, int Xp);

// Dungeon state returned by GET /api/world/dungeon/{zoneId}/state.
public record DungeonStateDto(
    Guid ZoneId,
    string ZoneName,
    string Status,
    int CurrentFloorOrdinal,
    int BonusXp,
    IReadOnlyList<DungeonFloorDto> Floors);

public record DungeonFloorDto(
    Guid Id,
    int Ordinal,
    string Name,
    string Emoji,
    string ActivityType,
    string TargetKind,
    double TargetValue,
    double ProgressValue,
    string Status);

// SetDestination response — includes forfeit count so the client can surface
// a snackbar when leaving mid-dungeon abandons the run.
public record SetWorldDestinationResult(int ForfeitedFloors);
