namespace LifeLevel.Modules.Leaderboard.Domain;

public static class LeaderboardRules
{
    /// <summary>How many players are listed; the viewer's own row is always added.</summary>
    public const int TopCount = 100;

    /// <summary>How many of the players just ahead of you are watched for passes.</summary>
    public const int WatchDepth = 10;

    /// <summary>Passes that pay per week; later passes still move you up but pay nothing.</summary>
    public const int MaxPaidPassesPerWeek = 10;

    /// <summary>Weekly boards reset on Monday 00:00 UTC.</summary>
    public static DateTime WeekStart(DateTime utcNow)
    {
        var day = utcNow.Date;
        var sinceMonday = ((int)day.DayOfWeek + 6) % 7;
        return DateTime.SpecifyKind(day.AddDays(-sinceMonday), DateTimeKind.Utc);
    }

    /// <summary>Passing someone nearer the top pays more.</summary>
    public static (int Coins, int Gems) PassReward(int passedRank) => passedRank switch
    {
        <= 3 => (80, 2),
        <= 10 => (60, 1),
        _ => (40, 0),
    };
}
