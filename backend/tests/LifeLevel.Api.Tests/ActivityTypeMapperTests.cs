using LifeLevel.Modules.Integrations.Application.Mappers;

namespace LifeLevel.Api.Tests;

public class ActivityTypeMapperTests
{
    // ── Strava → Internal ────────────────────────────────────────────────────

    [Theory]
    [InlineData("Run",              ActivityTypeMapper.Types.Running)]
    [InlineData("TrailRun",         ActivityTypeMapper.Types.Running)]
    [InlineData("VirtualRun",       ActivityTypeMapper.Types.Running)]
    [InlineData("Ride",             ActivityTypeMapper.Types.Cycling)]
    [InlineData("MountainBikeRide", ActivityTypeMapper.Types.Cycling)]
    [InlineData("GravelRide",       ActivityTypeMapper.Types.Cycling)]
    [InlineData("VirtualRide",      ActivityTypeMapper.Types.Cycling)]
    [InlineData("EBikeRide",        ActivityTypeMapper.Types.Cycling)]
    [InlineData("Swim",             ActivityTypeMapper.Types.Swimming)]
    [InlineData("OpenWaterSwim",    ActivityTypeMapper.Types.Swimming)]
    [InlineData("Hike",             ActivityTypeMapper.Types.Hiking)]
    [InlineData("Walk",             ActivityTypeMapper.Types.Walking)]
    [InlineData("RockClimbing",     ActivityTypeMapper.Types.Climbing)]
    [InlineData("IceClimbing",      ActivityTypeMapper.Types.Climbing)]
    [InlineData("Yoga",             ActivityTypeMapper.Types.Yoga)]
    [InlineData("Pilates",          ActivityTypeMapper.Types.Yoga)]
    public void FromStrava_KnownTypes_MapsCorrectly(string stravaSport, string expected)
    {
        Assert.Equal(expected, ActivityTypeMapper.FromStrava(stravaSport));
    }

    [Theory]
    [InlineData("WeightTraining")]
    [InlineData("Crossfit")]
    [InlineData("Elliptical")]
    [InlineData("SomeNewSport")]
    [InlineData("")]
    public void FromStrava_UnknownTypes_DefaultToGym(string stravaSport)
    {
        Assert.Equal(ActivityTypeMapper.Types.Gym, ActivityTypeMapper.FromStrava(stravaSport));
    }

    // ── Garmin → Internal ────────────────────────────────────────────────────

    [Theory]
    [InlineData("running",            ActivityTypeMapper.Types.Running)]
    [InlineData("trail_running",      ActivityTypeMapper.Types.Running)]
    [InlineData("treadmill_running",  ActivityTypeMapper.Types.Running)]
    [InlineData("track_running",      ActivityTypeMapper.Types.Running)]
    [InlineData("cycling",            ActivityTypeMapper.Types.Cycling)]
    [InlineData("road_cycling",       ActivityTypeMapper.Types.Cycling)]
    [InlineData("mountain_biking",    ActivityTypeMapper.Types.Cycling)]
    [InlineData("indoor_cycling",     ActivityTypeMapper.Types.Cycling)]
    [InlineData("gravel_cycling",     ActivityTypeMapper.Types.Cycling)]
    [InlineData("swimming",           ActivityTypeMapper.Types.Swimming)]
    [InlineData("lap_swimming",       ActivityTypeMapper.Types.Swimming)]
    [InlineData("open_water_swimming", ActivityTypeMapper.Types.Swimming)]
    [InlineData("hiking",             ActivityTypeMapper.Types.Hiking)]
    [InlineData("walking",            ActivityTypeMapper.Types.Walking)]
    [InlineData("rock_climbing",      ActivityTypeMapper.Types.Climbing)]
    [InlineData("bouldering",         ActivityTypeMapper.Types.Climbing)]
    [InlineData("yoga",               ActivityTypeMapper.Types.Yoga)]
    [InlineData("pilates",            ActivityTypeMapper.Types.Yoga)]
    public void FromGarmin_KnownTypes_MapsCorrectly(string garminType, string expected)
    {
        Assert.Equal(expected, ActivityTypeMapper.FromGarmin(garminType));
    }

    [Theory]
    [InlineData("strength_training")]
    [InlineData("other")]
    [InlineData("")]
    public void FromGarmin_UnknownTypes_DefaultToGym(string garminType)
    {
        Assert.Equal(ActivityTypeMapper.Types.Gym, ActivityTypeMapper.FromGarmin(garminType));
    }

    [Fact]
    public void FromGarmin_IsCaseInsensitive()
    {
        Assert.Equal(ActivityTypeMapper.Types.Running, ActivityTypeMapper.FromGarmin("RUNNING"));
        Assert.Equal(ActivityTypeMapper.Types.Cycling, ActivityTypeMapper.FromGarmin("Mountain_Biking"));
    }

    [Fact]
    public void FromGarmin_NullInput_DefaultsToGym()
    {
        Assert.Equal(ActivityTypeMapper.Types.Gym, ActivityTypeMapper.FromGarmin(null!));
    }
}
