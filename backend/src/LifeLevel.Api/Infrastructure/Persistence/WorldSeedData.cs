using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Enums;
using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using LifeLevel.Modules.Adventure.Dungeons.Domain.Enums;
using LifeLevel.SharedKernel.Enums;

// Type alias: 'WorldZone' class name conflicts with the 'LifeLevel.Modules.WorldZone' namespace
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Api.Infrastructure.Persistence;

public static class WorldSeedData
{
    // World
    public static readonly Guid WorldId = new("cc000001-0000-0000-0000-000000000000");

    // Zone IDs
    private static readonly Guid Z01 = new("aa000001-0000-0000-0000-000000000000"); // First Fork
    private static readonly Guid Z02 = new("aa000002-0000-0000-0000-000000000000"); // Forest of Endurance
    private static readonly Guid Z03 = new("aa000003-0000-0000-0000-000000000000"); // Mountains of Strength
    private static readonly Guid Z04 = new("aa000004-0000-0000-0000-000000000000"); // Deepwood Trails
    private static readonly Guid Z05 = new("aa000005-0000-0000-0000-000000000000"); // Iron Forge
    private static readonly Guid Z06 = new("aa000006-0000-0000-0000-000000000000"); // The Convergence
    private static readonly Guid Z07 = new("aa000007-0000-0000-0000-000000000000"); // Ocean of Balance
    private static readonly Guid Z08 = new("aa000008-0000-0000-0000-000000000000"); // Desert Expanse
    private static readonly Guid Z09 = new("aa000009-0000-0000-0000-000000000000"); // Snow Peaks
    private static readonly Guid Z10 = new("aa000010-0000-0000-0000-000000000000"); // The Grand Nexus
    private static readonly Guid Z11 = new("aa000011-0000-0000-0000-000000000000"); // Void Wastes
    private static readonly Guid Z12 = new("aa000012-0000-0000-0000-000000000000"); // Shadow Vale
    private static readonly Guid Z13 = new("aa000013-0000-0000-0000-000000000000"); // Fire Summit
    private static readonly Guid Z14 = new("aa000014-0000-0000-0000-000000000000"); // Crystal Citadel
    private static readonly Guid Z15 = new("aa000015-0000-0000-0000-000000000000"); // The Final Gate
    private static readonly Guid Z16 = new("aa000016-0000-0000-0000-000000000000"); // The Eternal Nexus

    // MapNode IDs — Z02 Forest of Endurance (4 nodes)
    private static readonly Guid N01 = new("cc000101-0000-0000-0000-000000000000"); // Forest Entrance
    private static readonly Guid N02 = new("cc000102-0000-0000-0000-000000000000"); // Ancient Oak
    private static readonly Guid N03 = new("cc000103-0000-0000-0000-000000000000"); // Mossy Ruins
    private static readonly Guid N04 = new("cc000104-0000-0000-0000-000000000000"); // Forest Heart

    // MapNode IDs — Z03 Mountains of Strength (4 nodes)
    private static readonly Guid N05 = new("cc000201-0000-0000-0000-000000000000"); // Mountain Base
    private static readonly Guid N06 = new("cc000202-0000-0000-0000-000000000000"); // Rocky Slope
    private static readonly Guid N07 = new("cc000203-0000-0000-0000-000000000000"); // Storm Peak
    private static readonly Guid N08 = new("cc000204-0000-0000-0000-000000000000"); // Summit

    // MapNode IDs — Z04 Deepwood Trails (4 nodes)
    private static readonly Guid N09  = new("cc000301-0000-0000-0000-000000000000"); // Trail Entrance
    private static readonly Guid N10  = new("cc000302-0000-0000-0000-000000000000"); // Twisted Roots
    private static readonly Guid N11  = new("cc000303-0000-0000-0000-000000000000"); // Hollow Glade
    private static readonly Guid N12  = new("cc000304-0000-0000-0000-000000000000"); // Ancient Heart

    // MapNode IDs — Z05 Iron Forge (4 nodes)
    private static readonly Guid N13  = new("cc000401-0000-0000-0000-000000000000"); // Forge Gate
    private static readonly Guid N14  = new("cc000402-0000-0000-0000-000000000000"); // Ember Hall
    private static readonly Guid N15  = new("cc000403-0000-0000-0000-000000000000"); // Anvil Pit
    private static readonly Guid N16  = new("cc000404-0000-0000-0000-000000000000"); // Master's Furnace

    // MapNode IDs — Z07 Ocean of Balance (4 nodes)
    private static readonly Guid N17  = new("cc000501-0000-0000-0000-000000000000"); // Shore Landing
    private static readonly Guid N18  = new("cc000502-0000-0000-0000-000000000000"); // Tidal Shelf
    private static readonly Guid N19  = new("cc000503-0000-0000-0000-000000000000"); // Sunken Arch
    private static readonly Guid N20  = new("cc000504-0000-0000-0000-000000000000"); // Deep Horizon

    // MapNode IDs — Z08 Desert Expanse (4 nodes)
    private static readonly Guid N21  = new("cc000601-0000-0000-0000-000000000000"); // Dune Gateway
    private static readonly Guid N22  = new("cc000602-0000-0000-0000-000000000000"); // Scorched Mesa
    private static readonly Guid N23  = new("cc000603-0000-0000-0000-000000000000"); // Mirage Oasis
    private static readonly Guid N24  = new("cc000604-0000-0000-0000-000000000000"); // Sand Tomb

    // MapNode IDs — Z09 Snow Peaks (4 nodes)
    private static readonly Guid N25  = new("cc000701-0000-0000-0000-000000000000"); // Frost Gate
    private static readonly Guid N26  = new("cc000702-0000-0000-0000-000000000000"); // Ice Bridge
    private static readonly Guid N27  = new("cc000703-0000-0000-0000-000000000000"); // Blizzard Pass
    private static readonly Guid N28  = new("cc000704-0000-0000-0000-000000000000"); // Glacial Throne

    // MapNode IDs — Z11 Void Wastes (4 nodes)
    private static readonly Guid N29  = new("cc000801-0000-0000-0000-000000000000"); // Void Edge
    private static readonly Guid N30  = new("cc000802-0000-0000-0000-000000000000"); // Ashen Plain
    private static readonly Guid N31  = new("cc000803-0000-0000-0000-000000000000"); // Shattered Spire
    private static readonly Guid N32  = new("cc000804-0000-0000-0000-000000000000"); // The Abyss

    // MapNode IDs — Z12 Shadow Vale (4 nodes)
    private static readonly Guid N33  = new("cc000901-0000-0000-0000-000000000000"); // Mist Gate
    private static readonly Guid N34  = new("cc000902-0000-0000-0000-000000000000"); // Dark Hollow
    private static readonly Guid N35  = new("cc000903-0000-0000-0000-000000000000"); // Wraith Crossing
    private static readonly Guid N36  = new("cc000904-0000-0000-0000-000000000000"); // Shadow Sanctum

    // MapNode IDs — Z13 Fire Summit (4 nodes)
    private static readonly Guid N37  = new("cc001001-0000-0000-0000-000000000000"); // Lava Foothills
    private static readonly Guid N38  = new("cc001002-0000-0000-0000-000000000000"); // Cinder Climb
    private static readonly Guid N39  = new("cc001003-0000-0000-0000-000000000000"); // Magma Ridge
    private static readonly Guid N40  = new("cc001004-0000-0000-0000-000000000000"); // Inferno Crown

    // MapNode IDs — Z14 Crystal Citadel (4 nodes)
    private static readonly Guid N41  = new("cc001101-0000-0000-0000-000000000000"); // Crystal Gate
    private static readonly Guid N42  = new("cc001102-0000-0000-0000-000000000000"); // Prism Hall
    private static readonly Guid N43  = new("cc001103-0000-0000-0000-000000000000"); // Refraction Tower
    private static readonly Guid N44  = new("cc001104-0000-0000-0000-000000000000"); // Radiant Throne

    // MapNode IDs — Z16 The Eternal Nexus (4 nodes)
    private static readonly Guid N45  = new("cc001201-0000-0000-0000-000000000000"); // Nexus Threshold
    private static readonly Guid N46  = new("cc001202-0000-0000-0000-000000000000"); // Convergence Point
    private static readonly Guid N47  = new("cc001203-0000-0000-0000-000000000000"); // Eternity's Edge
    private static readonly Guid N48  = new("cc001204-0000-0000-0000-000000000000"); // The Eternal Core

    // MapEdge IDs — local map edges (Z02)
    private static readonly Guid ME01 = new("dd000001-0000-0000-0000-000000000000"); // N01→N02
    private static readonly Guid ME02 = new("dd000002-0000-0000-0000-000000000000"); // N02→N03
    private static readonly Guid ME03 = new("dd000003-0000-0000-0000-000000000000"); // N03→N04
    // MapEdge IDs — local map edges (Z03)
    private static readonly Guid ME04 = new("dd000004-0000-0000-0000-000000000000"); // N05→N06
    private static readonly Guid ME05 = new("dd000005-0000-0000-0000-000000000000"); // N06→N07
    private static readonly Guid ME06 = new("dd000006-0000-0000-0000-000000000000"); // N07→N08
    // MapEdge IDs — local map edges (Z04 Deepwood Trails)
    private static readonly Guid ME07 = new("dd000007-0000-0000-0000-000000000000"); // N09→N10
    private static readonly Guid ME08 = new("dd000008-0000-0000-0000-000000000000"); // N10→N11
    private static readonly Guid ME09 = new("dd000009-0000-0000-0000-000000000000"); // N11→N12
    // MapEdge IDs — local map edges (Z05 Iron Forge)
    private static readonly Guid ME10 = new("dd000010-0000-0000-0000-000000000000"); // N13→N14
    private static readonly Guid ME11 = new("dd000011-0000-0000-0000-000000000000"); // N14→N15
    private static readonly Guid ME12 = new("dd000012-0000-0000-0000-000000000000"); // N15→N16
    // MapEdge IDs — local map edges (Z07 Ocean of Balance)
    private static readonly Guid ME13 = new("dd000013-0000-0000-0000-000000000000"); // N17→N18
    private static readonly Guid ME14 = new("dd000014-0000-0000-0000-000000000000"); // N18→N19
    private static readonly Guid ME15 = new("dd000015-0000-0000-0000-000000000000"); // N19→N20
    // MapEdge IDs — local map edges (Z08 Desert Expanse)
    private static readonly Guid ME16 = new("dd000016-0000-0000-0000-000000000000"); // N21→N22
    private static readonly Guid ME17 = new("dd000017-0000-0000-0000-000000000000"); // N22→N23
    private static readonly Guid ME18 = new("dd000018-0000-0000-0000-000000000000"); // N23→N24
    // MapEdge IDs — local map edges (Z09 Snow Peaks)
    private static readonly Guid ME19 = new("dd000019-0000-0000-0000-000000000000"); // N25→N26
    private static readonly Guid ME20 = new("dd000020-0000-0000-0000-000000000000"); // N26→N27
    private static readonly Guid ME21 = new("dd000021-0000-0000-0000-000000000000"); // N27→N28
    // MapEdge IDs — local map edges (Z11 Void Wastes)
    private static readonly Guid ME22 = new("dd000022-0000-0000-0000-000000000000"); // N29→N30
    private static readonly Guid ME23 = new("dd000023-0000-0000-0000-000000000000"); // N30→N31
    private static readonly Guid ME24 = new("dd000024-0000-0000-0000-000000000000"); // N31→N32
    // MapEdge IDs — local map edges (Z12 Shadow Vale)
    private static readonly Guid ME25 = new("dd000025-0000-0000-0000-000000000000"); // N33→N34
    private static readonly Guid ME26 = new("dd000026-0000-0000-0000-000000000000"); // N34→N35
    private static readonly Guid ME27 = new("dd000027-0000-0000-0000-000000000000"); // N35→N36
    // MapEdge IDs — local map edges (Z13 Fire Summit)
    private static readonly Guid ME28 = new("dd000028-0000-0000-0000-000000000000"); // N37→N38
    private static readonly Guid ME29 = new("dd000029-0000-0000-0000-000000000000"); // N38→N39
    private static readonly Guid ME30 = new("dd000030-0000-0000-0000-000000000000"); // N39→N40
    // MapEdge IDs — local map edges (Z14 Crystal Citadel)
    private static readonly Guid ME31 = new("dd000031-0000-0000-0000-000000000000"); // N41→N42
    private static readonly Guid ME32 = new("dd000032-0000-0000-0000-000000000000"); // N42→N43
    private static readonly Guid ME33 = new("dd000033-0000-0000-0000-000000000000"); // N43→N44
    // MapEdge IDs — local map edges (Z16 The Eternal Nexus)
    private static readonly Guid ME34 = new("dd000034-0000-0000-0000-000000000000"); // N45→N46
    private static readonly Guid ME35 = new("dd000035-0000-0000-0000-000000000000"); // N46→N47
    private static readonly Guid ME36 = new("dd000036-0000-0000-0000-000000000000"); // N47→N48

    // Boss IDs
    private static readonly Guid B01 = new("ee000001-0000-0000-0000-000000000000");
    private static readonly Guid B02 = new("ee000002-0000-0000-0000-000000000000");

    // Chest IDs
    private static readonly Guid CH01 = new("ff000001-0000-0000-0000-000000000000");
    private static readonly Guid CH02 = new("ff000002-0000-0000-0000-000000000000");
    private static readonly Guid CH03 = new("ff000003-0000-0000-0000-000000000000");
    private static readonly Guid CH04 = new("ff000004-0000-0000-0000-000000000000");

    // Dungeon portal IDs
    private static readonly Guid D01 = new("a1000001-0000-0000-0000-000000000000");
    private static readonly Guid D02 = new("a1000002-0000-0000-0000-000000000000");
    private static readonly Guid D03 = new("a1000003-0000-0000-0000-000000000000");

    // Dungeon floor IDs
    private static readonly Guid DF01 = new("a2000001-0000-0000-0000-000000000000");
    private static readonly Guid DF02 = new("a2000002-0000-0000-0000-000000000000");
    private static readonly Guid DF03 = new("a2000003-0000-0000-0000-000000000000");
    private static readonly Guid DF04 = new("a2000004-0000-0000-0000-000000000000");
    private static readonly Guid DF05 = new("a2000005-0000-0000-0000-000000000000");
    private static readonly Guid DF06 = new("a2000006-0000-0000-0000-000000000000");
    private static readonly Guid DF07 = new("a2000007-0000-0000-0000-000000000000");
    private static readonly Guid DF08 = new("a2000008-0000-0000-0000-000000000000");
    private static readonly Guid DF09 = new("a2000009-0000-0000-0000-000000000000");
    private static readonly Guid DF10 = new("a2000010-0000-0000-0000-000000000000");

    // Crossroads IDs
    private static readonly Guid CR01 = new("a3000001-0000-0000-0000-000000000000");
    private static readonly Guid CR02 = new("a3000002-0000-0000-0000-000000000000");

    // Crossroads path IDs
    private static readonly Guid CP01 = new("a4000001-0000-0000-0000-000000000000");
    private static readonly Guid CP02 = new("a4000002-0000-0000-0000-000000000000");
    private static readonly Guid CP03 = new("a4000003-0000-0000-0000-000000000000");
    private static readonly Guid CP04 = new("a4000004-0000-0000-0000-000000000000");

    // Edge IDs
    private static readonly Guid E01 = new("bb000001-0000-0000-0000-000000000000");
    private static readonly Guid E02 = new("bb000002-0000-0000-0000-000000000000");
    private static readonly Guid E03 = new("bb000003-0000-0000-0000-000000000000");
    private static readonly Guid E04 = new("bb000004-0000-0000-0000-000000000000");
    private static readonly Guid E05 = new("bb000005-0000-0000-0000-000000000000");
    private static readonly Guid E06 = new("bb000006-0000-0000-0000-000000000000");
    private static readonly Guid E07 = new("bb000007-0000-0000-0000-000000000000");
    private static readonly Guid E08 = new("bb000008-0000-0000-0000-000000000000");
    private static readonly Guid E09 = new("bb000009-0000-0000-0000-000000000000");
    private static readonly Guid E10 = new("bb000010-0000-0000-0000-000000000000");
    private static readonly Guid E11 = new("bb000011-0000-0000-0000-000000000000");
    private static readonly Guid E12 = new("bb000012-0000-0000-0000-000000000000");
    private static readonly Guid E13 = new("bb000013-0000-0000-0000-000000000000");
    private static readonly Guid E14 = new("bb000014-0000-0000-0000-000000000000");
    private static readonly Guid E15 = new("bb000015-0000-0000-0000-000000000000");
    private static readonly Guid E16 = new("bb000016-0000-0000-0000-000000000000");
    private static readonly Guid E17 = new("bb000017-0000-0000-0000-000000000000");
    private static readonly Guid E18 = new("bb000018-0000-0000-0000-000000000000");
    private static readonly Guid E19 = new("bb000019-0000-0000-0000-000000000000");
    private static readonly Guid E20 = new("bb000020-0000-0000-0000-000000000000");
    private static readonly Guid E21 = new("bb000021-0000-0000-0000-000000000000");

    public static World CreateWorld() => new()
    {
        Id = WorldId,
        Name = "World v1",
        IsActive = true,
        CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
    };

    // PositionX is in pixel coords (0–390, matching the admin canvas width).
    // Flutter's ZoneData.fromApiModel divides by 390 to get relativeX.
    // PositionY is unused by Flutter (Y is derived from Tier).
    public static IReadOnlyList<WorldZoneEntity> CreateZones(Guid worldId) =>
    [
        // Tier 0 — start (crossroads → 2 paths)
        new WorldZoneEntity { Id = Z01, WorldId = worldId, Name = "First Fork", Icon = "⑂",
            Region = "Lowlands", Tier = 0, PositionX = 195f, PositionY = 0f,
            LevelRequirement = 1, TotalXp = 0, TotalDistanceKm = 0,
            IsStartZone = true, IsCrossroads = true,
            Description = "Where every journey begins. Two roads stretch ahead — choose your path." },

        // Tier 1 — 2 unique starting paths
        new WorldZoneEntity { Id = Z02, WorldId = worldId, Name = "Forest of Endurance", Icon = "🌲",
            Region = "Verdant Reach", Tier = 1, PositionX = 117f, PositionY = 0f,
            LevelRequirement = 1, TotalXp = 600, TotalDistanceKm = 6,
            IsStartZone = false, IsCrossroads = false,
            Description = "Ancient trees stretch for miles. Every step demands endurance." },

        new WorldZoneEntity { Id = Z03, WorldId = worldId, Name = "Mountains of Strength", Icon = "⛰️",
            Region = "Stonereach", Tier = 1, PositionX = 273f, PositionY = 0f,
            LevelRequirement = 1, TotalXp = 600, TotalDistanceKm = 6,
            IsStartZone = false, IsCrossroads = false,
            Description = "Iron peaks forged by ancient forces. Only the strong reach the summit." },

        // Tier 2 — deeper unique zones
        new WorldZoneEntity { Id = Z04, WorldId = worldId, Name = "Deepwood Trails", Icon = "🍃",
            Region = "Verdant Reach", Tier = 2, PositionX = 117f, PositionY = 0f,
            LevelRequirement = 3, TotalXp = 900, TotalDistanceKm = 8,
            IsStartZone = false, IsCrossroads = false,
            Description = "The forest deepens. Ancient paths wind through roots and ruins." },

        new WorldZoneEntity { Id = Z05, WorldId = worldId, Name = "Iron Forge", Icon = "🔨",
            Region = "Stonereach", Tier = 2, PositionX = 273f, PositionY = 0f,
            LevelRequirement = 3, TotalXp = 900, TotalDistanceKm = 8,
            IsStartZone = false, IsCrossroads = false,
            Description = "Molten iron and sweat. This is where legends temper themselves." },

        // Tier 3 — 3-way crossroads
        new WorldZoneEntity { Id = Z06, WorldId = worldId, Name = "The Convergence", Icon = "🔀",
            Region = "Nexus", Tier = 3, PositionX = 195f, PositionY = 0f,
            LevelRequirement = 5, TotalXp = 0, TotalDistanceKm = 10,
            IsStartZone = false, IsCrossroads = true,
            Description = "All paths meet here. Three roads diverge into the unknown." },

        // Tier 4 — 3 paths
        new WorldZoneEntity { Id = Z07, WorldId = worldId, Name = "Ocean of Balance", Icon = "🌊",
            Region = "Azure Shore", Tier = 4, PositionX = 78f, PositionY = 0f,
            LevelRequirement = 6, TotalXp = 1500, TotalDistanceKm = 12,
            IsStartZone = false, IsCrossroads = false,
            Description = "Endless waves teach patience. Balance is the only way forward." },

        new WorldZoneEntity { Id = Z08, WorldId = worldId, Name = "Desert Expanse", Icon = "🏜️",
            Region = "Ashen Wastes", Tier = 4, PositionX = 195f, PositionY = 0f,
            LevelRequirement = 6, TotalXp = 1500, TotalDistanceKm = 12,
            IsStartZone = false, IsCrossroads = false,
            Description = "Scorching sands stretch to the horizon. Only the relentless survive." },

        new WorldZoneEntity { Id = Z09, WorldId = worldId, Name = "Snow Peaks", Icon = "❄️",
            Region = "Glacial Expanse", Tier = 4, PositionX = 312f, PositionY = 0f,
            LevelRequirement = 6, TotalXp = 1500, TotalDistanceKm = 12,
            IsStartZone = false, IsCrossroads = false,
            Description = "Frozen peaks cut through the clouds. Cold forges clarity." },

        // Tier 5 — 4-way crossroads
        new WorldZoneEntity { Id = Z10, WorldId = worldId, Name = "The Grand Nexus", Icon = "⭕",
            Region = "Nexus", Tier = 5, PositionX = 195f, PositionY = 0f,
            LevelRequirement = 10, TotalXp = 0, TotalDistanceKm = 15,
            IsStartZone = false, IsCrossroads = true,
            Description = "Four great roads converge and split. The world holds its breath." },

        // Tier 6 — 4 paths
        new WorldZoneEntity { Id = Z11, WorldId = worldId, Name = "Void Wastes", Icon = "🌑",
            Region = "Shadowvast", Tier = 6, PositionX = 58f, PositionY = 0f,
            LevelRequirement = 12, TotalXp = 3000, TotalDistanceKm = 20,
            IsStartZone = false, IsCrossroads = false,
            Description = "Darkness without end. Only legends dare tread here." },

        new WorldZoneEntity { Id = Z12, WorldId = worldId, Name = "Shadow Vale", Icon = "🌫️",
            Region = "Shadowvast", Tier = 6, PositionX = 156f, PositionY = 0f,
            LevelRequirement = 12, TotalXp = 3000, TotalDistanceKm = 20,
            IsStartZone = false, IsCrossroads = false,
            Description = "Mist hides everything. Agility is your only guide." },

        new WorldZoneEntity { Id = Z13, WorldId = worldId, Name = "Fire Summit", Icon = "🔥",
            Region = "Ignis", Tier = 6, PositionX = 234f, PositionY = 0f,
            LevelRequirement = 12, TotalXp = 3000, TotalDistanceKm = 20,
            IsStartZone = false, IsCrossroads = false,
            Description = "A volcanic peak where strength is tested by fire." },

        new WorldZoneEntity { Id = Z14, WorldId = worldId, Name = "Crystal Citadel", Icon = "💎",
            Region = "Solara", Tier = 6, PositionX = 332f, PositionY = 0f,
            LevelRequirement = 12, TotalXp = 3000, TotalDistanceKm = 20,
            IsStartZone = false, IsCrossroads = false,
            Description = "A fortress of light and crystal. Flexibility unlocks its secrets." },

        // Tier 7 — final crossroads (→ 1)
        new WorldZoneEntity { Id = Z15, WorldId = worldId, Name = "The Final Gate", Icon = "🔱",
            Region = "Apex", Tier = 7, PositionX = 195f, PositionY = 0f,
            LevelRequirement = 18, TotalXp = 0, TotalDistanceKm = 25,
            IsStartZone = false, IsCrossroads = true,
            Description = "The last threshold. Beyond lies the end of all paths." },

        // Tier 8 — final zone
        new WorldZoneEntity { Id = Z16, WorldId = worldId, Name = "The Eternal Nexus", Icon = "✨",
            Region = "Apex", Tier = 8, PositionX = 195f, PositionY = 0f,
            LevelRequirement = 25, TotalXp = 10000, TotalDistanceKm = 30,
            IsStartZone = false, IsCrossroads = false,
            Description = "The heart of everything. Time and space converge. This is the end — and the beginning." },
    ];

    public static IReadOnlyList<WorldZoneEdge> CreateEdges(Guid worldId) =>
    [
        // Tier 0 → Tier 1 (First Fork splits to 2)
        new WorldZoneEdge { Id = E01, FromZoneId = Z01, ToZoneId = Z02, DistanceKm = 6,  IsBidirectional = true },
        new WorldZoneEdge { Id = E02, FromZoneId = Z01, ToZoneId = Z03, DistanceKm = 6,  IsBidirectional = true },

        // Tier 1 → Tier 2 (each path continues)
        new WorldZoneEdge { Id = E03, FromZoneId = Z02, ToZoneId = Z04, DistanceKm = 8,  IsBidirectional = true },
        new WorldZoneEdge { Id = E04, FromZoneId = Z03, ToZoneId = Z05, DistanceKm = 8,  IsBidirectional = true },

        // Tier 2 → Tier 3 (both paths converge at 3-way crossroads)
        new WorldZoneEdge { Id = E05, FromZoneId = Z04, ToZoneId = Z06, DistanceKm = 10, IsBidirectional = true },
        new WorldZoneEdge { Id = E06, FromZoneId = Z05, ToZoneId = Z06, DistanceKm = 10, IsBidirectional = true },

        // Tier 3 → Tier 4 (3-way split)
        new WorldZoneEdge { Id = E07, FromZoneId = Z06, ToZoneId = Z07, DistanceKm = 12, IsBidirectional = true },
        new WorldZoneEdge { Id = E08, FromZoneId = Z06, ToZoneId = Z08, DistanceKm = 12, IsBidirectional = true },
        new WorldZoneEdge { Id = E09, FromZoneId = Z06, ToZoneId = Z09, DistanceKm = 12, IsBidirectional = true },

        // Tier 4 → Tier 5 (3 paths converge at 4-way crossroads)
        new WorldZoneEdge { Id = E10, FromZoneId = Z07, ToZoneId = Z10, DistanceKm = 15, IsBidirectional = true },
        new WorldZoneEdge { Id = E11, FromZoneId = Z08, ToZoneId = Z10, DistanceKm = 15, IsBidirectional = true },
        new WorldZoneEdge { Id = E12, FromZoneId = Z09, ToZoneId = Z10, DistanceKm = 15, IsBidirectional = true },

        // Tier 5 → Tier 6 (4-way split)
        new WorldZoneEdge { Id = E13, FromZoneId = Z10, ToZoneId = Z11, DistanceKm = 20, IsBidirectional = true },
        new WorldZoneEdge { Id = E14, FromZoneId = Z10, ToZoneId = Z12, DistanceKm = 20, IsBidirectional = true },
        new WorldZoneEdge { Id = E15, FromZoneId = Z10, ToZoneId = Z13, DistanceKm = 20, IsBidirectional = true },
        new WorldZoneEdge { Id = E16, FromZoneId = Z10, ToZoneId = Z14, DistanceKm = 20, IsBidirectional = true },

        // Tier 6 → Tier 7 (all 4 paths converge at Final Gate)
        new WorldZoneEdge { Id = E17, FromZoneId = Z11, ToZoneId = Z15, DistanceKm = 25, IsBidirectional = true },
        new WorldZoneEdge { Id = E18, FromZoneId = Z12, ToZoneId = Z15, DistanceKm = 25, IsBidirectional = true },
        new WorldZoneEdge { Id = E19, FromZoneId = Z13, ToZoneId = Z15, DistanceKm = 25, IsBidirectional = true },
        new WorldZoneEdge { Id = E20, FromZoneId = Z14, ToZoneId = Z15, DistanceKm = 25, IsBidirectional = true },

        // Tier 7 → Tier 8 (Final Gate → Eternal Nexus)
        new WorldZoneEdge { Id = E21, FromZoneId = Z15, ToZoneId = Z16, DistanceKm = 30, IsBidirectional = true },
    ];

    public static IReadOnlyList<MapNode> CreateMapNodes() =>
    [
        // ── Z02: Forest of Endurance ─────────────────────────────────────────────
        new MapNode
        {
            Id = N01, WorldZoneId = Z02,
            Name = "Forest Entrance", Icon = "🌳",
            Description = "Where the canopy begins. A worn path leads deeper into the woods.",
            Type = MapNodeType.Zone,
            Region = MapRegion.ForestOfEndurance,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N02, WorldZoneId = Z02,
            Name = "Ancient Oak", Icon = "🌲",
            Description = "A colossal tree older than memory. Strange carvings mark its bark.",
            Type = MapNodeType.Zone,
            Region = MapRegion.ForestOfEndurance,
            PositionX = 300, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N03, WorldZoneId = Z02,
            Name = "Mossy Ruins", Icon = "🏚️",
            Description = "The remains of a forgotten outpost. Something valuable might be buried here.",
            Type = MapNodeType.Chest,
            Region = MapRegion.ForestOfEndurance,
            PositionX = 180, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N04, WorldZoneId = Z02,
            Name = "Forest Heart", Icon = "💚",
            Description = "The deepest part of the forest. Ancient power pulses here.",
            Type = MapNodeType.Boss,
            Region = MapRegion.ForestOfEndurance,
            PositionX = 280, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z03: Mountains of Strength ───────────────────────────────────────────
        new MapNode
        {
            Id = N05, WorldZoneId = Z03,
            Name = "Mountain Base", Icon = "⛺",
            Description = "Base camp at the mountain's foot. The peak looms above.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N06, WorldZoneId = Z03,
            Name = "Rocky Slope", Icon = "🪨",
            Description = "Loose gravel and steep inclines test your footing at every step.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 320, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N07, WorldZoneId = Z03,
            Name = "Storm Peak", Icon = "⛈️",
            Description = "Lightning strikes and howling winds. Only the strong press forward.",
            Type = MapNodeType.Crossroads,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 200, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N08, WorldZoneId = Z03,
            Name = "Summit", Icon = "🏔️",
            Description = "The roof of the world. The view from here is worth every painful step.",
            Type = MapNodeType.Boss,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 150, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z04: Deepwood Trails ──────────────────────────────────────────────────
        new MapNode
        {
            Id = N09, WorldZoneId = Z04,
            Name = "Trail Entrance", Icon = "🍃",
            Description = "The forest grows dense here. Gnarled roots claw at the path.",
            Type = MapNodeType.Zone,
            Region = MapRegion.ForestOfEndurance,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N10, WorldZoneId = Z04,
            Name = "Twisted Roots", Icon = "🌿",
            Description = "Enormous roots twist above and below. Every step is a puzzle.",
            Type = MapNodeType.Chest,
            Region = MapRegion.ForestOfEndurance,
            PositionX = 310, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N11, WorldZoneId = Z04,
            Name = "Hollow Glade", Icon = "🌑",
            Description = "A clearing where sunlight never reaches. Strange silence fills the air.",
            Type = MapNodeType.Crossroads,
            Region = MapRegion.ForestOfEndurance,
            PositionX = 180, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N12, WorldZoneId = Z04,
            Name = "Ancient Heart", Icon = "💫",
            Description = "The oldest tree in existence. Its roots reach the core of the world.",
            Type = MapNodeType.Dungeon,
            Region = MapRegion.ForestOfEndurance,
            PositionX = 290, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z05: Iron Forge ───────────────────────────────────────────────────────
        new MapNode
        {
            Id = N13, WorldZoneId = Z05,
            Name = "Forge Gate", Icon = "🔩",
            Description = "Smoke-stained walls mark the entrance to the forge district.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N14, WorldZoneId = Z05,
            Name = "Ember Hall", Icon = "🔥",
            Description = "Walls of smoldering coal radiate punishing heat. Endure to advance.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 300, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N15, WorldZoneId = Z05,
            Name = "Anvil Pit", Icon = "⚒️",
            Description = "The rhythmic thunder of hammers never stops. Strength is forged here.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 170, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N16, WorldZoneId = Z05,
            Name = "Master's Furnace", Icon = "🔨",
            Description = "The greatest forge ever built. Only masters of strength stand before it.",
            Type = MapNodeType.Dungeon,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 280, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z07: Ocean of Balance ─────────────────────────────────────────────────
        new MapNode
        {
            Id = N17, WorldZoneId = Z07,
            Name = "Shore Landing", Icon = "🏖️",
            Description = "Warm sand and crashing surf. The ocean stretches endlessly ahead.",
            Type = MapNodeType.Zone,
            Region = MapRegion.OceanOfBalance,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N18, WorldZoneId = Z07,
            Name = "Tidal Shelf", Icon = "🌊",
            Description = "Submerged stone shelves rise and fall with the tide. Time your movement.",
            Type = MapNodeType.Zone,
            Region = MapRegion.OceanOfBalance,
            PositionX = 310, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N19, WorldZoneId = Z07,
            Name = "Sunken Arch", Icon = "🐚",
            Description = "Ancient stone arches half-swallowed by the sea. Balance or be swept away.",
            Type = MapNodeType.Chest,
            Region = MapRegion.OceanOfBalance,
            PositionX = 185, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N20, WorldZoneId = Z07,
            Name = "Deep Horizon", Icon = "🌅",
            Description = "Where ocean meets sky. Perfect equilibrium reigns at the edge of the world.",
            Type = MapNodeType.Zone,
            Region = MapRegion.OceanOfBalance,
            PositionX = 280, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z08: Desert Expanse ───────────────────────────────────────────────────
        new MapNode
        {
            Id = N21, WorldZoneId = Z08,
            Name = "Dune Gateway", Icon = "🏜️",
            Description = "The first dunes rise before you. The sun is merciless here.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Desert,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N22, WorldZoneId = Z08,
            Name = "Scorched Mesa", Icon = "🌋",
            Description = "A flat-topped rock formation baked by centuries of sun. No shade anywhere.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Desert,
            PositionX = 305, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N23, WorldZoneId = Z08,
            Name = "Mirage Oasis", Icon = "🌴",
            Description = "A splash of green in the endless gold. Real — but only for those who push on.",
            Type = MapNodeType.Chest,
            Region = MapRegion.Desert,
            PositionX = 180, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N24, WorldZoneId = Z08,
            Name = "Sand Tomb", Icon = "⏳",
            Description = "Half-buried ruins of a lost civilization. The sands claim everything in time.",
            Type = MapNodeType.Dungeon,
            Region = MapRegion.Desert,
            PositionX = 285, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z09: Snow Peaks ───────────────────────────────────────────────────────
        new MapNode
        {
            Id = N25, WorldZoneId = Z09,
            Name = "Frost Gate", Icon = "🧊",
            Description = "An archway of ancient ice marks the boundary of the frozen realm.",
            Type = MapNodeType.Zone,
            Region = MapRegion.SnowPeaks,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N26, WorldZoneId = Z09,
            Name = "Ice Bridge", Icon = "❄️",
            Description = "A bridge of pure ice spans a chasm of wind. One wrong step is fatal.",
            Type = MapNodeType.Zone,
            Region = MapRegion.SnowPeaks,
            PositionX = 315, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N27, WorldZoneId = Z09,
            Name = "Blizzard Pass", Icon = "🌨️",
            Description = "White-out conditions. Only your stamina can guide you through.",
            Type = MapNodeType.Zone,
            Region = MapRegion.SnowPeaks,
            PositionX = 185, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N28, WorldZoneId = Z09,
            Name = "Glacial Throne", Icon = "👑",
            Description = "A throne carved from a single glacier. Cold forges the sharpest minds.",
            Type = MapNodeType.Zone,
            Region = MapRegion.SnowPeaks,
            PositionX = 280, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z11: Void Wastes ──────────────────────────────────────────────────────
        new MapNode
        {
            Id = N29, WorldZoneId = Z11,
            Name = "Void Edge", Icon = "🌑",
            Description = "Where light ends and the void begins. Only legends dare step further.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Swamps,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N30, WorldZoneId = Z11,
            Name = "Ashen Plain", Icon = "🩶",
            Description = "Grey ash covers everything. The remains of a world consumed by nothing.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Swamps,
            PositionX = 305, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N31, WorldZoneId = Z11,
            Name = "Shattered Spire", Icon = "🗿",
            Description = "The broken remains of a tower that once touched the heavens.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Swamps,
            PositionX = 175, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N32, WorldZoneId = Z11,
            Name = "The Abyss", Icon = "🕳️",
            Description = "A chasm with no visible bottom. The void stares back at those who look.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Swamps,
            PositionX = 285, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z12: Shadow Vale ──────────────────────────────────────────────────────
        new MapNode
        {
            Id = N33, WorldZoneId = Z12,
            Name = "Mist Gate", Icon = "🌫️",
            Description = "Thick mist swallows the path ahead. Agility is your only compass.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Swamps,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N34, WorldZoneId = Z12,
            Name = "Dark Hollow", Icon = "🦇",
            Description = "A sunken depression where shadows gather unnaturally. Move quickly.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Swamps,
            PositionX = 310, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N35, WorldZoneId = Z12,
            Name = "Wraith Crossing", Icon = "👻",
            Description = "A bridge where spectral figures drift. Cross without hesitation.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Swamps,
            PositionX = 180, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N36, WorldZoneId = Z12,
            Name = "Shadow Sanctum", Icon = "🖤",
            Description = "The heart of the vale. Darkness here is absolute — only the swift survive.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Swamps,
            PositionX = 290, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z13: Fire Summit ──────────────────────────────────────────────────────
        new MapNode
        {
            Id = N37, WorldZoneId = Z13,
            Name = "Lava Foothills", Icon = "🌋",
            Description = "Rivers of molten rock cut through the lower slopes. The heat is extreme.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N38, WorldZoneId = Z13,
            Name = "Cinder Climb", Icon = "🔥",
            Description = "Ash rains down constantly. Each handhold crumbles under weak grip.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 305, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N39, WorldZoneId = Z13,
            Name = "Magma Ridge", Icon = "♨️",
            Description = "A narrow ridge between two lava flows. One step wrong means oblivion.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 180, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N40, WorldZoneId = Z13,
            Name = "Inferno Crown", Icon = "👑",
            Description = "The crater rim. Smoke and fire pour endlessly into the sky. You made it.",
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 285, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z14: Crystal Citadel ──────────────────────────────────────────────────
        new MapNode
        {
            Id = N41, WorldZoneId = Z14,
            Name = "Crystal Gate", Icon = "💎",
            Description = "Towering pillars of crystal flank the entrance. Light refracts in every direction.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Ashfield,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N42, WorldZoneId = Z14,
            Name = "Prism Hall", Icon = "🔮",
            Description = "A hall of living crystal. Walls shift and reshape as you move through.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Ashfield,
            PositionX = 310, PositionY = 300,
            LevelRequirement = 1, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N43, WorldZoneId = Z14,
            Name = "Refraction Tower", Icon = "🌟",
            Description = "A soaring spire that splits light into its components. Clarity of mind is required.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Ashfield,
            PositionX = 185, PositionY = 500,
            LevelRequirement = 2, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N44, WorldZoneId = Z14,
            Name = "Radiant Throne", Icon = "✨",
            Description = "Pure light crystallized into a seat of power. Flexibility of body and mind unlocks it.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Ashfield,
            PositionX = 280, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },

        // ── Z16: The Eternal Nexus ────────────────────────────────────────────────
        new MapNode
        {
            Id = N45, WorldZoneId = Z16,
            Name = "Nexus Threshold", Icon = "🌀",
            Description = "The air shimmers with pure energy. Reality bends at the edge of the nexus.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Ashfield,
            PositionX = 200, PositionY = 100,
            LevelRequirement = 1, RewardXp = 0,
            IsStartNode = true, IsHidden = false
        },
        new MapNode
        {
            Id = N46, WorldZoneId = Z16,
            Name = "Convergence Point", Icon = "⭕",
            Description = "All timelines intersect here. Every path you have ever walked echoes in this place.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Ashfield,
            PositionX = 310, PositionY = 300,
            LevelRequirement = 2, RewardXp = 150,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N47, WorldZoneId = Z16,
            Name = "Eternity's Edge", Icon = "🔱",
            Description = "The boundary between existence and nothing. Time stops for those who reach it.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Ashfield,
            PositionX = 185, PositionY = 500,
            LevelRequirement = 3, RewardXp = 250,
            IsStartNode = false, IsHidden = false
        },
        new MapNode
        {
            Id = N48, WorldZoneId = Z16,
            Name = "The Eternal Core", Icon = "💫",
            Description = "The heart of everything. Time and space converge. This is the end — and the beginning.",
            Type = MapNodeType.Zone,
            Region = MapRegion.Ashfield,
            PositionX = 280, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },
    ];

    public static IReadOnlyList<MapEdge> CreateMapEdges() =>
    [
        // Z02 Forest of Endurance edges
        new MapEdge { Id = ME01, FromNodeId = N01, ToNodeId = N02, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME02, FromNodeId = N02, ToNodeId = N03, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME03, FromNodeId = N03, ToNodeId = N04, DistanceKm = 3,   IsBidirectional = true },

        // Z03 Mountains of Strength edges
        new MapEdge { Id = ME04, FromNodeId = N05, ToNodeId = N06, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME05, FromNodeId = N06, ToNodeId = N07, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME06, FromNodeId = N07, ToNodeId = N08, DistanceKm = 3,   IsBidirectional = true },

        // Z04 Deepwood Trails edges
        new MapEdge { Id = ME07, FromNodeId = N09, ToNodeId = N10, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME08, FromNodeId = N10, ToNodeId = N11, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME09, FromNodeId = N11, ToNodeId = N12, DistanceKm = 3,   IsBidirectional = true },

        // Z05 Iron Forge edges
        new MapEdge { Id = ME10, FromNodeId = N13, ToNodeId = N14, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME11, FromNodeId = N14, ToNodeId = N15, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME12, FromNodeId = N15, ToNodeId = N16, DistanceKm = 3,   IsBidirectional = true },

        // Z07 Ocean of Balance edges
        new MapEdge { Id = ME13, FromNodeId = N17, ToNodeId = N18, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME14, FromNodeId = N18, ToNodeId = N19, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME15, FromNodeId = N19, ToNodeId = N20, DistanceKm = 3,   IsBidirectional = true },

        // Z08 Desert Expanse edges
        new MapEdge { Id = ME16, FromNodeId = N21, ToNodeId = N22, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME17, FromNodeId = N22, ToNodeId = N23, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME18, FromNodeId = N23, ToNodeId = N24, DistanceKm = 3,   IsBidirectional = true },

        // Z09 Snow Peaks edges
        new MapEdge { Id = ME19, FromNodeId = N25, ToNodeId = N26, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME20, FromNodeId = N26, ToNodeId = N27, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME21, FromNodeId = N27, ToNodeId = N28, DistanceKm = 3,   IsBidirectional = true },

        // Z11 Void Wastes edges
        new MapEdge { Id = ME22, FromNodeId = N29, ToNodeId = N30, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME23, FromNodeId = N30, ToNodeId = N31, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME24, FromNodeId = N31, ToNodeId = N32, DistanceKm = 3,   IsBidirectional = true },

        // Z12 Shadow Vale edges
        new MapEdge { Id = ME25, FromNodeId = N33, ToNodeId = N34, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME26, FromNodeId = N34, ToNodeId = N35, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME27, FromNodeId = N35, ToNodeId = N36, DistanceKm = 3,   IsBidirectional = true },

        // Z13 Fire Summit edges
        new MapEdge { Id = ME28, FromNodeId = N37, ToNodeId = N38, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME29, FromNodeId = N38, ToNodeId = N39, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME30, FromNodeId = N39, ToNodeId = N40, DistanceKm = 3,   IsBidirectional = true },

        // Z14 Crystal Citadel edges
        new MapEdge { Id = ME31, FromNodeId = N41, ToNodeId = N42, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME32, FromNodeId = N42, ToNodeId = N43, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME33, FromNodeId = N43, ToNodeId = N44, DistanceKm = 3,   IsBidirectional = true },

        // Z16 The Eternal Nexus edges
        new MapEdge { Id = ME34, FromNodeId = N45, ToNodeId = N46, DistanceKm = 2,   IsBidirectional = true },
        new MapEdge { Id = ME35, FromNodeId = N46, ToNodeId = N47, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME36, FromNodeId = N47, ToNodeId = N48, DistanceKm = 3,   IsBidirectional = true },
    ];

    public static IReadOnlyList<Boss> CreateBosses() =>
    [
        new Boss
        {
            Id = B01, NodeId = N04,
            Name = "Forest Guardian", Icon = "🐉",
            MaxHp = 500, RewardXp = 300, TimerDays = 3, IsMini = true
        },
        new Boss
        {
            Id = B02, NodeId = N08,
            Name = "Mountain Colossus", Icon = "👹",
            MaxHp = 1200, RewardXp = 700, TimerDays = 7, IsMini = false
        },
    ];

    public static IReadOnlyList<Chest> CreateChests() =>
    [
        new Chest { Id = CH01, NodeId = N03, Rarity = ChestRarity.Uncommon, RewardXp = 200 },
        new Chest { Id = CH02, NodeId = N10, Rarity = ChestRarity.Common,   RewardXp = 100 },
        new Chest { Id = CH03, NodeId = N19, Rarity = ChestRarity.Epic,     RewardXp = 600 },
        new Chest { Id = CH04, NodeId = N23, Rarity = ChestRarity.Rare,     RewardXp = 350 },
    ];

    public static IReadOnlyList<DungeonPortal> CreateDungeons() =>
    [
        new DungeonPortal
        {
            Id = D01, NodeId = N12,
            Name = "Ancient Roots Dungeon", TotalFloors = 3,
            Floors =
            [
                new DungeonFloor { Id = DF01, DungeonPortalId = D01, FloorNumber = 1, RequiredActivity = ActivityType.Running, RequiredMinutes = 20, RewardXp = 150 },
                new DungeonFloor { Id = DF02, DungeonPortalId = D01, FloorNumber = 2, RequiredActivity = ActivityType.Hiking,  RequiredMinutes = 30, RewardXp = 250 },
                new DungeonFloor { Id = DF03, DungeonPortalId = D01, FloorNumber = 3, RequiredActivity = ActivityType.Yoga,    RequiredMinutes = 20, RewardXp = 200 },
            ]
        },
        new DungeonPortal
        {
            Id = D02, NodeId = N16,
            Name = "Iron Gauntlet", TotalFloors = 3,
            Floors =
            [
                new DungeonFloor { Id = DF04, DungeonPortalId = D02, FloorNumber = 1, RequiredActivity = ActivityType.Gym,      RequiredMinutes = 30, RewardXp = 200 },
                new DungeonFloor { Id = DF05, DungeonPortalId = D02, FloorNumber = 2, RequiredActivity = ActivityType.Gym,      RequiredMinutes = 45, RewardXp = 300 },
                new DungeonFloor { Id = DF06, DungeonPortalId = D02, FloorNumber = 3, RequiredActivity = ActivityType.Climbing, RequiredMinutes = 30, RewardXp = 350 },
            ]
        },
        new DungeonPortal
        {
            Id = D03, NodeId = N24,
            Name = "Sand Tomb Depths", TotalFloors = 4,
            Floors =
            [
                new DungeonFloor { Id = DF07, DungeonPortalId = D03, FloorNumber = 1, RequiredActivity = ActivityType.Running,  RequiredMinutes = 20, RewardXp = 150 },
                new DungeonFloor { Id = DF08, DungeonPortalId = D03, FloorNumber = 2, RequiredActivity = ActivityType.Cycling,  RequiredMinutes = 30, RewardXp = 200 },
                new DungeonFloor { Id = DF09, DungeonPortalId = D03, FloorNumber = 3, RequiredActivity = ActivityType.Yoga,     RequiredMinutes = 25, RewardXp = 200 },
                new DungeonFloor { Id = DF10, DungeonPortalId = D03, FloorNumber = 4, RequiredActivity = ActivityType.Climbing, RequiredMinutes = 30, RewardXp = 400 },
            ]
        },
    ];

    public static IReadOnlyList<Crossroads> CreateCrossroads() =>
    [
        new Crossroads
        {
            Id = CR01, NodeId = N07,
            Paths =
            [
                new CrossroadsPath { Id = CP01, CrossroadsId = CR01, Name = "Cliff Shortcut", DistanceKm = 1.5, Difficulty = CrossroadsPathDifficulty.Hard,    EstimatedDays = 2, RewardXp = 300, AdditionalRequirement = "Strength" },
                new CrossroadsPath { Id = CP02, CrossroadsId = CR01, Name = "Ridge Trail",    DistanceKm = 3.0, Difficulty = CrossroadsPathDifficulty.Moderate, EstimatedDays = 4, RewardXp = 200, AdditionalRequirement = null },
            ]
        },
        new Crossroads
        {
            Id = CR02, NodeId = N11,
            Paths =
            [
                new CrossroadsPath { Id = CP03, CrossroadsId = CR02, Name = "The Dark Way",   DistanceKm = 2.0, Difficulty = CrossroadsPathDifficulty.Hard, EstimatedDays = 3, RewardXp = 350, AdditionalRequirement = null },
                new CrossroadsPath { Id = CP04, CrossroadsId = CR02, Name = "The Light Path", DistanceKm = 2.5, Difficulty = CrossroadsPathDifficulty.Easy, EstimatedDays = 3, RewardXp = 150, AdditionalRequirement = null },
            ]
        },
    ];
}
