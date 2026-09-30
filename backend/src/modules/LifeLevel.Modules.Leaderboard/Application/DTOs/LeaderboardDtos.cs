namespace LifeLevel.Modules.Leaderboard.Application.DTOs;

public record LeaderboardEntryDto(
    int Rank, Guid UserId, string Username, string? AvatarEmoji, int Level, string? ClassName,
    double Score, bool IsMe);

/// <summary>The viewer's own row. <see cref="Rank"/> is null when they are not on this board.</summary>
public record LeaderboardMeDto(
    int? Rank, double Score, int Total, string? NextUsername, double? GapToNext);

public record LeaderboardChestDto(int Stack, int Coins, int Gems);

public record LeaderboardDto(
    string Scope, string Metric, bool Available, string? ContextName,
    DateTime? ResetsAtUtc, IReadOnlyList<LeaderboardEntryDto> Entries,
    LeaderboardMeDto Me, LeaderboardChestDto Chest);

public record LeaderboardPassDto(string Username, string? AvatarEmoji, int Coins, int Gems);

public record LeaderboardChestOpenedDto(int Coins, int Gems, IReadOnlyList<LeaderboardPassDto> Passes);
