using LifeLevel.SharedKernel.Calculators;

namespace LifeLevel.Api.Tests;

public class BossCombatCalculatorTests
{
    [Theory]
    [InlineData(100, 0, 100)]
    [InlineData(100, 100, 50)]
    [InlineData(100, 300, 25)]
    public void ApplyMitigation_UsesArmorCurve(int raw, int armor, int expected)
    {
        Assert.Equal(expected, BossCombatCalculator.ApplyMitigation(raw, armor));
    }

    [Fact]
    public void ApplyPlayerModifiers_AppliesPowerThenActiveBossTalent()
    {
        Assert.Equal(330, BossCombatCalculator.ApplyPlayerModifiers(200, 1.5, 10));
    }

    [Theory]
    [InlineData(1, 1, 8, 8)]
    [InlineData(5, 32, 10, 7)]
    [InlineData(11, 68, 12, 6)]
    [InlineData(15, 85, 12, 6)]
    public void BalanceProfile_MatchesConfiguredTurnTargets(
        int chapter, int level, int turns, int hits)
    {
        var profile = BossBalanceCalculator.ForChapter(chapter, level);

        Assert.Equal(turns, profile.TargetTurns);
        Assert.Equal(hits, profile.TargetHitsToDefeatPlayer);
        Assert.Equal(profile.ExpectedDamagePerTurn * turns, profile.MaxHp);
        Assert.True(BossCombatCalculator.ApplyMitigation(
            profile.CounterattackDamage, profile.ExpectedPlayerDefense) * hits
            >= profile.ExpectedPlayerHealth);
    }
}
