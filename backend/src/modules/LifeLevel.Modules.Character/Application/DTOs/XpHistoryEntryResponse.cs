namespace LifeLevel.Modules.Character.Application.DTOs;

public record XpHistoryEntryResponse(
    Guid Id,
    string Source,
    string SourceEmoji,
    string Description,
    long Xp,
    DateTime EarnedAt
);
