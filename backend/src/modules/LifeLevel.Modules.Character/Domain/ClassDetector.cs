using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Character.Domain;

public enum ClassDetectionState
{
    /// <summary>Fewer than <see cref="ClassDetector.MinWorkouts"/> workouts — the player picks a class by hand.</summary>
    Insufficient,
    /// <summary>One activity type is at least 75% of active time. Grants a devotion trait.</summary>
    Devoted,
    /// <summary>Swimming, cycling and running each take at least 15% → Stormrunner.</summary>
    Multisport,
    /// <summary>Top two groups are close and form a known pair → hybrid class.</summary>
    Hybrid,
    /// <summary>No group reaches 40% → Sentinel, the all-rounder.</summary>
    Balanced,
    /// <summary>Top two groups within 10 points and no hybrid exists — the player chooses.</summary>
    Close,
    /// <summary>One group clearly leads.</summary>
    Clear,
}

public record ClassGroupShare(string ClassName, int Minutes, double Share);

public record ClassDetectionResult(
    ClassDetectionState State,
    string? RecommendedClass,
    IReadOnlyList<string> Alternatives,
    string? TraitKey,
    ActivityType? DevotedType,
    IReadOnlyList<ClassGroupShare> Groups,
    int Workouts,
    int Minutes);

/// <summary>
/// Reads a player's recent training mix (active minutes per activity type) and
/// picks the class that fits it. Pure — no I/O — so the rules are unit-testable.
/// </summary>
public static class ClassDetector
{
    public const int MinWorkouts = 3;
    public const double DevotedShare = 0.75;
    public const double MultisportShare = 0.15;
    public const double HybridMinShare = 0.30;
    public const double HybridMaxGap = 0.15;
    public const double ClearMinShare = 0.40;
    public const double CloseMaxGap = 0.10;

    public const string Sentinel = "Sentinel";
    public const string Stormrunner = "Stormrunner";

    /// <summary>Which class each activity type builds toward.</summary>
    public static string GroupOf(ActivityType type) => type switch
    {
        ActivityType.Running or ActivityType.Cycling => "Ranger",
        ActivityType.Gym => "Warrior",
        ActivityType.Yoga => "Mystic",
        ActivityType.Swimming => "Tidecaller",
        ActivityType.Climbing => "Cragborn",
        ActivityType.Hiking or ActivityType.Walking => "Wayfarer",
        _ => "Warrior",
    };

    private static readonly Dictionary<string, string> HybridPairs = new()
    {
        [PairKey("Ranger", "Warrior")] = "Vanguard",
        [PairKey("Warrior", "Mystic")] = "Spellblade",
        [PairKey("Ranger", "Mystic")] = "Druid",
        [PairKey("Wayfarer", "Mystic")] = "Druid",
    };

    private static string PairKey(string a, string b) =>
        string.CompareOrdinal(a, b) < 0 ? $"{a}+{b}" : $"{b}+{a}";

    public static ClassDetectionResult Detect(IReadOnlyList<ActivityMixEntry> mix)
    {
        var workouts = mix.Sum(m => m.Workouts);
        var minutes = mix.Sum(m => m.Minutes);

        var groups = mix
            .GroupBy(m => GroupOf(m.Type))
            .Select(g => new ClassGroupShare(
                g.Key,
                g.Sum(m => m.Minutes),
                minutes > 0 ? (double)g.Sum(m => m.Minutes) / minutes : 0))
            .OrderByDescending(g => g.Minutes)
            .ThenBy(g => g.ClassName, StringComparer.Ordinal)
            .ToList();

        ClassDetectionResult Result(ClassDetectionState state, string? pick, IEnumerable<string> alts,
            string? trait = null, ActivityType? devoted = null) =>
            new(state, pick, alts.Where(a => a != pick).Distinct().ToList(), trait, devoted, groups, workouts, minutes);

        if (workouts < MinWorkouts || minutes <= 0 || groups.Count == 0)
            return Result(ClassDetectionState.Insufficient, null, []);

        var top = groups[0];
        var second = groups.Count > 1 ? groups[1] : null;
        var runnerUp = second is null ? Array.Empty<string>() : [second.ClassName];

        double TypeShare(ActivityType t) =>
            (double)mix.Where(m => m.Type == t).Sum(m => m.Minutes) / minutes;

        var topType = mix
            .GroupBy(m => m.Type)
            .Select(g => (Type: g.Key, Minutes: g.Sum(m => m.Minutes)))
            .OrderByDescending(t => t.Minutes)
            .First();
        if ((double)topType.Minutes / minutes >= DevotedShare)
        {
            var cls = GroupOf(topType.Type);
            return Result(ClassDetectionState.Devoted, cls, runnerUp,
                trait: $"devoted:{topType.Type}", devoted: topType.Type);
        }

        if (TypeShare(ActivityType.Swimming) >= MultisportShare &&
            TypeShare(ActivityType.Cycling) >= MultisportShare &&
            TypeShare(ActivityType.Running) >= MultisportShare)
        {
            return Result(ClassDetectionState.Multisport, Stormrunner,
                [top.ClassName, .. runnerUp]);
        }

        if (second is not null &&
            second.Share >= HybridMinShare &&
            top.Share - second.Share <= HybridMaxGap &&
            HybridPairs.TryGetValue(PairKey(top.ClassName, second.ClassName), out var hybrid))
        {
            return Result(ClassDetectionState.Hybrid, hybrid, [top.ClassName, second.ClassName]);
        }

        if (top.Share < ClearMinShare)
            return Result(ClassDetectionState.Balanced, Sentinel, [top.ClassName]);

        if (second is not null && top.Share - second.Share <= CloseMaxGap)
            return Result(ClassDetectionState.Close, top.ClassName, [second.ClassName]);

        return Result(ClassDetectionState.Clear, top.ClassName, runnerUp);
    }
}
