namespace LifeLevel.SharedKernel.DTOs;

public record LevelUpUnlocksDto(
    int StatPointsGained,
    IReadOnlyList<GrantedItemInfo> GrantedItems,
    IReadOnlyList<UnlockedZoneInfo> UnlockedZones
);

public record GrantedItemInfo(
    Guid ItemId,
    string Name,
    string Icon,
    string Rarity,
    string Slot
);

public record UnlockedZoneInfo(
    Guid ZoneId,
    string Name,
    string Icon,
    string Region,
    int LevelRequirement
);
