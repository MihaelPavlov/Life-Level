using LifeLevel.SharedKernel.Abstractions;

namespace LifeLevel.Modules.Modes.Application.DTOs;

public record ModeWalletDto(long Coins, int Gems, int TalentCrystals);

public record BurnChainLinkDto(
    Guid ActivityId, string Type, int DurationMinutes, int Calories,
    DateTime LoggedAt, string Kind, int? BarBefore, int Multiplier, int Coins);

public record BurnChainDto(
    Guid? RunId, string Phase, DateTime? StartedAt, DateTime? EndsAt,
    string? EndReason, IReadOnlyList<BurnChainLinkDto> Links,
    int AcknowledgedLinks, int? Bar, int TotalCoins, int Beats,
    int TalentCrystals, DateTime? CollectedAt, DateTime? NextStartAt);

public record DelveOptionDto(
    string Path, string Event, string Stat, int Coins, int Recommended,
    double SuccessChance, bool Boosted, bool Guaranteed, double ItemChance);

public record DelveHistoryDto(
    int Chamber, string Path, string Event, bool Succeeded, int Coins,
    string? ItemName, string? ItemIcon, string? ItemRarity);

public record DelveItemDto(Guid ItemId, string Name, string Icon, string Rarity, string? InventoryIconUrl);

public record DelveRunDto(
    Guid Id, string Phase, string? EndReason, int Chamber, string FeaturedStat,
    int Secured, int AtRisk, int RoomsCleared, string? ChosenPath,
    IReadOnlyList<DelveOptionDto> Options, IReadOnlyList<DelveHistoryDto> History,
    IReadOnlyList<DelveItemDto> Items, int Payout, int TalentCrystals,
    DateTime StartedAt, DateTime? SettledAt);

public record TreasureDelveStatusDto(
    int RunsEarned, int RunsUsed, int RunsLeft, string FeaturedStat,
    int BestRun, DateTime ResetAtUtc, DelveRunDto? ActiveRun);

public record ModesOverviewDto(ModeWalletDto Wallet, BurnChainDto BurnChain, TreasureDelveStatusDto TreasureDelve);

public record ChooseDelvePathRequest(string Path);

public class ModeRuleException(string code, string message) :
    DomainException(code, message, DomainErrorKind.Conflict);
