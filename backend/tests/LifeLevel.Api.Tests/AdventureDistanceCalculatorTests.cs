using LifeLevel.Modules.Activity.Domain;
using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Api.Tests;

public class AdventureDistanceCalculatorTests
{
    [Theory]
    [InlineData(ActivityType.Running, 5, 5)]
    [InlineData(ActivityType.Running, 20, 20)]
    [InlineData(ActivityType.Walking, 5, 5)]
    [InlineData(ActivityType.Hiking, 5, 5)]
    [InlineData(ActivityType.Cycling, 20, 5)]
    [InlineData(ActivityType.Swimming, 2, 8)]
    [InlineData(ActivityType.Gym, 5, 0)]
    [InlineData(ActivityType.Yoga, 5, 0)]
    [InlineData(ActivityType.Climbing, 5, 0)]
    public void Calculate_NormalizesOnlyMapDistance(ActivityType type, double realKm, double expectedAdventureKm)
    {
        Assert.Equal(expectedAdventureKm, AdventureDistanceCalculator.Calculate(type, realKm), precision: 8);
    }

    [Theory]
    [InlineData(null)]
    [InlineData(0.0)]
    [InlineData(-2.0)]
    public void Calculate_NonPositiveDistance_ReturnsZero(double? realKm)
    {
        Assert.Equal(0, AdventureDistanceCalculator.Calculate(ActivityType.Running, realKm));
    }
}
