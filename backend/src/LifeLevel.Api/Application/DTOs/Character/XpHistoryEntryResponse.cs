namespace LifeLevel.Api.Application.DTOs.Character;

public record XpHistoryEntryResponse(
    Guid Id,
    string Source,
    string SourceEmoji,
    string Description,
    long Xp,
    DateTime EarnedAt
);
