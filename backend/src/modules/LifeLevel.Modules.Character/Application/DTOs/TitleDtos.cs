namespace LifeLevel.Modules.Character.Application.DTOs;

public record TitleDto(
    Guid Id,
    string Emoji,
    string Name,
    string UnlockCondition,
    bool IsEarned,
    bool IsEquipped);

public record RankProgressionDto(
    string CurrentRank,
    int BossesDefeated,
    int BossesRequiredForNextRank,
    int BossesRemainingForNextRank,
    string? NextRank);

public record TitlesAndRanksResponse(
    string ActiveTitleEmoji,
    string ActiveTitleName,
    RankProgressionDto RankProgression,
    List<TitleDto> EarnedTitles,
    List<TitleDto> LockedTitles);

public record EquipTitleRequest(Guid TitleId);
