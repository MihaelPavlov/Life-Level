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
    IReadOnlyList<ZoneEdgeDto> Edges);

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
    int? LoreTotal);

public record ZoneEdgeDto(Guid FromId, Guid ToId);
