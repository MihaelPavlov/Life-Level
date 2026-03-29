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

    public static readonly CharacterClass[] SeedData =
    [
        Warrior,
        Ranger,
        Mystic,
        Sentinel,
    ];
}
