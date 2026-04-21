namespace LifeLevel.Modules.Character.Domain;

/// <summary>
/// Static reward table for the 7-step first-time-user tutorial (LL-035).
///
/// Payout schedule:
///   Step 1 → 25 XP
///   Step 2 → 25 XP
///   Step 3 → 50 XP
///   Step 4 → 50 XP
///   Step 5 → 50 XP
///   Step 6 → 50 XP
///   Step 7 → 250 XP + "Novice Adventurer" title unlock
///   Total  → 500 XP + title
///
/// Rewards are one-shot per character lifetime. The caller is responsible for checking
/// <c>Character.TutorialRewardsClaimed</c> before awarding; this class is pure lookup and
/// has no knowledge of persistence, services, or side effects. Safe to unit-test in isolation.
/// </summary>
public static class TutorialStepRewards
{
    /// <summary>Sum of XP across all 7 tutorial steps. Kept as a compile-time constant so callers
    /// (tests, docs, client preview UI) can reference the total without re-summing the table.</summary>
    public const int TotalXp = 500;

    /// <summary>Catalog key for the Novice Adventurer title unlocked on step 7. Matches the
    /// entry registered in <c>TitleCatalog</c>.</summary>
    public const string NoviceTitleKey = "novice-adventurer";

    /// <summary>
    /// Returns the XP reward for completing the given tutorial step.
    /// Valid steps are 1..7. Any other value (0, negative, or &gt; 7) returns 0 so that
    /// callers can safely probe without throwing — this mirrors the "no-op on unknown step"
    /// contract of <see cref="LifeLevel.SharedKernel.Ports.ICharacterTutorialPort"/>.
    /// </summary>
    public static int GetXp(int step) => step switch
    {
        1 => 25,
        2 => 25,
        3 => 50,
        4 => 50,
        5 => 50,
        6 => 50,
        7 => 250,
        _ => 0,
    };

    /// <summary>
    /// Returns the title catalog key unlocked by completing the given step, or <c>null</c> if
    /// the step does not award a title. Currently only step 7 unlocks a title
    /// (<see cref="NoviceTitleKey"/>).
    /// </summary>
    public static string? GetTitleKey(int step) => step switch
    {
        7 => NoviceTitleKey,
        _ => null,
    };
}
