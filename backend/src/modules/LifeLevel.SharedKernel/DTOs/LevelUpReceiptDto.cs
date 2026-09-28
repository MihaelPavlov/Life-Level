namespace LifeLevel.SharedKernel.DTOs;

public record LevelUpTitleInfo(Guid TitleId, string Name, string Emoji);
public record LevelUpAvatarInfo(string Name, string Emoji, int LevelRequirement);
public record LevelUpRegionInfo(Guid RegionId, string Name, string Emoji, int LevelRequirement);
public record LevelUpBlockedItemInfo(Guid ItemId, string Name, string Icon);

public record LevelUpReceiptDto(
    Guid Id,
    string Source,
    int PreviousLevel,
    int NewLevel,
    int BaseStatPointsGranted,
    int BonusStatPointsGranted,
    int PowerGained,
    int CoinsGranted,
    int PreviousInventorySlots,
    int NewInventorySlots,
    IReadOnlyList<GrantedItemInfo> GrantedItems,
    IReadOnlyList<LevelUpBlockedItemInfo> BlockedItems,
    IReadOnlyList<LevelUpTitleInfo> GrantedTitles,
    IReadOnlyList<LevelUpAvatarInfo> AvailableAvatars,
    IReadOnlyList<LevelUpRegionInfo> AvailableRegions,
    DateTime CreatedAt);
