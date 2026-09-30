namespace LifeLevel.Modules.Leaderboard.Domain.Entities;

/// <summary>
/// A player the user overtook on the weekly board. Unclaimed passes stack in
/// the rank-up chest until the user opens it.
/// </summary>
public class LeaderboardPass
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid PassedUserId { get; set; }
    public string PassedUsername { get; set; } = string.Empty;
    public string? PassedAvatarEmoji { get; set; }
    public DateTime WeekStartUtc { get; set; }
    public int Coins { get; set; }
    public int Gems { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? ClaimedAtUtc { get; set; }
}

/// <summary>
/// The players who were just ahead of the user at the last check. A pass is
/// someone from this list who is now behind.
/// </summary>
public class LeaderboardWatch
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public DateTime WeekStartUtc { get; set; }
    public string AheadJson { get; set; } = "[]";
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
}
