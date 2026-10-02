namespace LifeLevel.Modules.WorldZone.Application.DTOs;

public record RegionChestWalletDto(long Coins, int Gems);

public record RegionChestDto(
    Guid RegionId,
    int ChapterIndex,
    int Coins,
    int Gems,
    string Status,
    DateTime? ClaimedAtUtc);

public record RegionChestsDto(
    RegionChestWalletDto Wallet,
    IReadOnlyList<RegionChestDto> Regions);

public record RegionChestClaimResultDto(
    Guid RegionId,
    int Coins,
    int Gems,
    string Status,
    DateTime ClaimedAtUtc,
    RegionChestWalletDto Wallet);
