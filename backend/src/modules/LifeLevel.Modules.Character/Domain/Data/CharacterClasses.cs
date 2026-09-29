using LifeLevel.Modules.Character.Domain.Entities;

namespace LifeLevel.Modules.Character.Domain.Data;

public static class CharacterClasses
{
    public static readonly CharacterClass Warrior = new()
    {
        Id = Guid.Parse("aaaaaaaa-0001-0000-0000-000000000000"),
        Name = "Warrior",
        Emoji = "⚔️",
        Description = "Master of raw power. Gym sessions and heavy lifts are your domain.",
        Tagline = "Lift heavy. Hit harder.",
        StrMultiplier = 1.3f,
        EndMultiplier = 1.0f,
        AgiMultiplier = 1.0f,
        FlxMultiplier = 1.0f,
        StaMultiplier = 1.2f,
        IsActive = true,
    };

    public static readonly CharacterClass Ranger = new()
    {
        Id = Guid.Parse("aaaaaaaa-0002-0000-0000-000000000000"),
        Name = "Ranger",
        Emoji = "🏹",
        Description = "Born to endure the long road. Running and cycling are your strengths.",
        Tagline = "Run far. Run fast.",
        StrMultiplier = 1.0f,
        EndMultiplier = 1.3f,
        AgiMultiplier = 1.2f,
        FlxMultiplier = 1.0f,
        StaMultiplier = 1.0f,
        IsActive = true,
    };

    public static readonly CharacterClass Mystic = new()
    {
        Id = Guid.Parse("aaaaaaaa-0003-0000-0000-000000000000"),
        Name = "Mystic",
        Emoji = "🧘",
        Description = "Seeker of balance and flow. Yoga and flexibility training are your path.",
        Tagline = "Bend. Don't break.",
        StrMultiplier = 1.0f,
        EndMultiplier = 1.0f,
        AgiMultiplier = 1.0f,
        FlxMultiplier = 1.4f,
        StaMultiplier = 1.2f,
        IsActive = true,
    };

    public static readonly CharacterClass Sentinel = new()
    {
        Id = Guid.Parse("aaaaaaaa-0004-0000-0000-000000000000"),
        Name = "Sentinel",
        Emoji = "🛡️",
        Description = "Immovable. Unstoppable. All-round athlete with iron stamina.",
        Tagline = "Outlast everything.",
        StrMultiplier = 1.0f,
        EndMultiplier = 1.1f,
        AgiMultiplier = 1.0f,
        FlxMultiplier = 1.0f,
        StaMultiplier = 1.4f,
        IsActive = true,
    };

    public static readonly CharacterClass Tidecaller = new()
    {
        Id = Guid.Parse("aaaaaaaa-0005-0000-0000-000000000000"),
        Name = "Tidecaller",
        Emoji = "🌊",
        Description = "At home in the water. Swimming builds your endurance and calm.",
        Tagline = "Own the water.",
        StrMultiplier = 1.0f,
        EndMultiplier = 1.2f,
        AgiMultiplier = 1.0f,
        FlxMultiplier = 1.1f,
        StaMultiplier = 1.2f,
        IsActive = true,
    };

    public static readonly CharacterClass Cragborn = new()
    {
        Id = Guid.Parse("aaaaaaaa-0006-0000-0000-000000000000"),
        Name = "Cragborn",
        Emoji = "🧗",
        Description = "Born on the rock. Climbing trains your grip, pull and balance.",
        Tagline = "Grip, pull, rise.",
        StrMultiplier = 1.2f,
        EndMultiplier = 1.0f,
        AgiMultiplier = 1.2f,
        FlxMultiplier = 1.1f,
        StaMultiplier = 1.0f,
        IsActive = true,
    };

    public static readonly CharacterClass Wayfarer = new()
    {
        Id = Guid.Parse("aaaaaaaa-0007-0000-0000-000000000000"),
        Name = "Wayfarer",
        Emoji = "🥾",
        Description = "Long days on foot. Hikes and walks carry you across the world.",
        Tagline = "Every trail, every day.",
        StrMultiplier = 1.0f,
        EndMultiplier = 1.2f,
        AgiMultiplier = 1.0f,
        FlxMultiplier = 1.0f,
        StaMultiplier = 1.3f,
        IsActive = true,
    };

    public static readonly CharacterClass Vanguard = new()
    {
        Id = Guid.Parse("aaaaaaaa-0008-0000-0000-000000000000"),
        Name = "Vanguard",
        Emoji = "⚜️",
        Description = "Hybrid of Ranger and Warrior. You run and lift in the same week.",
        Tagline = "Run it, then lift it.",
        StrMultiplier = 1.2f,
        EndMultiplier = 1.2f,
        AgiMultiplier = 1.0f,
        FlxMultiplier = 1.0f,
        StaMultiplier = 1.1f,
        IsHybrid = true,
        IsActive = true,
    };

    public static readonly CharacterClass Spellblade = new()
    {
        Id = Guid.Parse("aaaaaaaa-0009-0000-0000-000000000000"),
        Name = "Spellblade",
        Emoji = "🗡️",
        Description = "Hybrid of Warrior and Mystic. Strength with flow.",
        Tagline = "Strength with flow.",
        StrMultiplier = 1.2f,
        EndMultiplier = 1.0f,
        AgiMultiplier = 1.1f,
        FlxMultiplier = 1.2f,
        StaMultiplier = 1.0f,
        IsHybrid = true,
        IsActive = true,
    };

    public static readonly CharacterClass Druid = new()
    {
        Id = Guid.Parse("aaaaaaaa-0010-0000-0000-000000000000"),
        Name = "Druid",
        Emoji = "🌿",
        Description = "Hybrid of Ranger and Mystic. Trails outside, stretch after.",
        Tagline = "Trails and stretch.",
        StrMultiplier = 1.0f,
        EndMultiplier = 1.2f,
        AgiMultiplier = 1.0f,
        FlxMultiplier = 1.3f,
        StaMultiplier = 1.0f,
        IsHybrid = true,
        IsActive = true,
    };

    public static readonly CharacterClass Stormrunner = new()
    {
        Id = Guid.Parse("aaaaaaaa-0011-0000-0000-000000000000"),
        Name = "Stormrunner",
        Emoji = "⚡",
        Description = "The multisport athlete. Swim, bike and run all feed your hero.",
        Tagline = "Swim, bike, run.",
        StrMultiplier = 1.0f,
        EndMultiplier = 1.3f,
        AgiMultiplier = 1.0f,
        FlxMultiplier = 1.0f,
        StaMultiplier = 1.2f,
        IsHybrid = true,
        IsActive = true,
    };

    public static readonly CharacterClass[] SeedData =
    [
        Warrior,
        Ranger,
        Mystic,
        Sentinel,
        Tidecaller,
        Cragborn,
        Wayfarer,
        Vanguard,
        Spellblade,
        Druid,
        Stormrunner,
    ];
}
