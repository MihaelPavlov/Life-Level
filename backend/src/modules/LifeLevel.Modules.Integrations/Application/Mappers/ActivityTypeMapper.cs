namespace LifeLevel.Modules.Integrations.Application.Mappers;

public static class ActivityTypeMapper
{
    public static class Types
    {
        public const string Running  = "Running";
        public const string Cycling  = "Cycling";
        public const string Swimming = "Swimming";
        public const string Hiking   = "Hiking";
        public const string Climbing = "Climbing";
        public const string Yoga     = "Yoga";
        public const string Gym      = "Gym";
    }

    /// <summary>Maps a Strava sport_type string to an internal activity type.</summary>
    public static string FromStrava(string sportType) => sportType switch
    {
        "Run" or "TrailRun" or "VirtualRun"                                           => Types.Running,
        "Ride" or "MountainBikeRide" or "GravelRide" or "VirtualRide" or "EBikeRide" => Types.Cycling,
        "Swim" or "OpenWaterSwim"                                                      => Types.Swimming,
        "Hike" or "Walk"                                                               => Types.Hiking,
        "RockClimbing" or "IceClimbing"                                                => Types.Climbing,
        "Yoga" or "Pilates"                                                            => Types.Yoga,
        _                                                                               => Types.Gym,
    };

    /// <summary>Maps a Garmin Connect activity type key to an internal activity type.</summary>
    public static string FromGarmin(string activityType) => activityType?.ToLowerInvariant() switch
    {
        "running" or "trail_running" or "treadmill_running" or "track_running"              => Types.Running,
        "cycling" or "road_cycling" or "mountain_biking" or "indoor_cycling" or "gravel_cycling" => Types.Cycling,
        "swimming" or "lap_swimming" or "open_water_swimming"                               => Types.Swimming,
        "hiking" or "walking"                                                               => Types.Hiking,
        "rock_climbing" or "bouldering"                                                     => Types.Climbing,
        "yoga" or "pilates"                                                                 => Types.Yoga,
        _                                                                                   => Types.Gym,
    };
}
