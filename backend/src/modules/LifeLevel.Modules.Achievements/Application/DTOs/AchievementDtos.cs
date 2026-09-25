namespace LifeLevel.Modules.Achievements.Application.DTOs;

public record AchievementDto(
    Guid Id,
    string Title,
    string Description,
    string Icon,
    string Category,
    string Tier,
    long XpReward,
    double TargetValue,
    string TargetUnit,
    double CurrentValue,
    bool IsUnlocked,
    DateTime? UnlockedAt,
    int CoinReward,
    int GemReward,
    bool IsClaimed,
    DateTime? ClaimedAt
);

public record CheckUnlocksResult(List<Guid> NewlyUnlockedIds);

// ── Reward Roads ─────────────────────────────────────────────────────────────

public record AchievementWalletDto(long Coins, int Gems);

/// <summary>Everything the Reward Roads screens need in one call.</summary>
public record AchievementRoadsResponse(
    AchievementWalletDto Wallet,
    int ReadyCount,
    int ChestsReady,
    List<AchievementRoadDto> Roads);

/// <summary>One category's road. <c>CurrentStage</c> is an index into <c>Stages</c>,
/// the first stage whose chest is not opened yet; -1 once every chest is open.</summary>
public record AchievementRoadDto(
    string Category,
    int Total,
    int Claimed,
    int Ready,
    int CurrentStage,
    List<AchievementStageDto> Stages);

/// <summary>One tier of a road. Its chest opens once every achievement in it is claimed.</summary>
public record AchievementStageDto(
    string Tier,
    string ChestKey,
    string ChestName,
    string ChestItemRarity,
    int ChestCoins,
    int ChestGems,
    int Total,
    int Unlocked,
    int Claimed,
    int Ready,
    bool ChestReady,
    bool ChestOpened,
    List<AchievementDto> Achievements);

public record AchievementStageKeyDto(string Category, string Tier);

public record AchievementClaimResult(
    List<Guid> ClaimedIds,
    long Xp,
    int Coins,
    int Gems,
    List<AchievementStageKeyDto> ChestsReady,
    AchievementWalletDto Wallet);

public record StageChestItemDto(Guid Id, string Name, string Icon, string Rarity, string? InventoryIconUrl);

public record StageChestOpenResult(
    string Category,
    string Tier,
    string ChestKey,
    string ChestName,
    StageChestItemDto? Item,
    int Coins,
    int Gems,
    AchievementWalletDto Wallet);

public class AchievementException(string code, string message) : InvalidOperationException(message)
{
    public string Code { get; } = code;
}
