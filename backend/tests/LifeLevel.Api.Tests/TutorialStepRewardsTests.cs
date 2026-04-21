using LifeLevel.Modules.Character.Domain;

namespace LifeLevel.Api.Tests;

/// <summary>
/// Unit tests for the pure reward-lookup table used by the LL-035 tutorial flow.
/// No DB / services / ports — this locks in the payout schedule so sibling services
/// (Character + Tutorial) can trust the numbers without their own duplicated tables.
/// </summary>
public class TutorialStepRewardsTests
{
    // ── GetXp ───────────────────────────────────────────────────────────────────

    [Theory]
    [InlineData(1, 25)]
    [InlineData(2, 25)]
    [InlineData(3, 50)]
    [InlineData(4, 50)]
    [InlineData(5, 50)]
    [InlineData(6, 50)]
    [InlineData(7, 250)]
    public void GetXp_ValidSteps_ReturnsSpecXp(int step, int expected)
    {
        Assert.Equal(expected, TutorialStepRewards.GetXp(step));
    }

    [Theory]
    [InlineData(0)]      // not started
    [InlineData(-1)]     // skipped marker
    [InlineData(8)]      // past the last step
    [InlineData(99)]     // arbitrary garbage
    [InlineData(int.MinValue)]
    [InlineData(int.MaxValue)]
    public void GetXp_OutOfRangeSteps_ReturnsZero(int step)
    {
        Assert.Equal(0, TutorialStepRewards.GetXp(step));
    }

    // ── GetTitleKey ─────────────────────────────────────────────────────────────

    [Fact]
    public void GetTitleKey_Step7_ReturnsNoviceKey()
    {
        Assert.Equal(TutorialStepRewards.NoviceTitleKey, TutorialStepRewards.GetTitleKey(7));
    }

    [Fact]
    public void NoviceTitleKey_IsStableCatalogKey()
    {
        // Contract test: the title key is used verbatim by ITitleUnlockPort and persisted
        // state. Changing this string is a breaking change — if this test fails, update
        // TitleCatalog.KeyToId and any client-side references in lockstep.
        Assert.Equal("novice-adventurer", TutorialStepRewards.NoviceTitleKey);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    [InlineData(2)]
    [InlineData(3)]
    [InlineData(4)]
    [InlineData(5)]
    [InlineData(6)]
    [InlineData(-1)]
    [InlineData(8)]
    [InlineData(99)]
    public void GetTitleKey_NonStep7_ReturnsNull(int step)
    {
        Assert.Null(TutorialStepRewards.GetTitleKey(step));
    }

    // ── TotalXp consistency ─────────────────────────────────────────────────────

    [Fact]
    public void TotalXp_EqualsSumOfStepXp()
    {
        var sum = 0;
        for (var step = 1; step <= 7; step++)
            sum += TutorialStepRewards.GetXp(step);

        Assert.Equal(TutorialStepRewards.TotalXp, sum);
    }

    [Fact]
    public void TotalXp_Is500()
    {
        // Spec-locking test: the ticket contract promises exactly 500 XP across all steps.
        Assert.Equal(500, TutorialStepRewards.TotalXp);
    }

    // ── One-shot rule (pure domain invariant) ──────────────────────────────────
    //
    // The one-shot guarantee ("XP is awarded ONLY if Character.TutorialRewardsClaimed == false")
    // is enforced by the caller (CharacterService / TutorialService) against the Character
    // entity — TutorialStepRewards itself is pure and has nothing to gate. These tests assert
    // the lookup stays idempotent / side-effect-free so callers can rely on it as a pure
    // reference in their one-shot checks.

    [Fact]
    public void GetXp_IsPureAndRepeatable()
    {
        // Call the same step 100 times — the table is a switch expression, but this guards
        // against someone "cleverly" swapping in a stateful implementation later.
        for (var i = 0; i < 100; i++)
            Assert.Equal(250, TutorialStepRewards.GetXp(7));
    }

    [Fact]
    public void GetTitleKey_IsPureAndRepeatable()
    {
        for (var i = 0; i < 100; i++)
            Assert.Equal(TutorialStepRewards.NoviceTitleKey, TutorialStepRewards.GetTitleKey(7));
    }
}
