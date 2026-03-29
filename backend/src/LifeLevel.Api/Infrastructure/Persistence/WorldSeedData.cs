using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Entities;

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

    // MapEdge IDs — local map edges
    private static readonly Guid ME01 = new("dd000001-0000-0000-0000-000000000000"); // N01→N02
    private static readonly Guid ME02 = new("dd000002-0000-0000-0000-000000000000"); // N02→N03
    private static readonly Guid ME03 = new("dd000003-0000-0000-0000-000000000000"); // N03→N04
    private static readonly Guid ME04 = new("dd000004-0000-0000-0000-000000000000"); // N05→N06
    private static readonly Guid ME05 = new("dd000005-0000-0000-0000-000000000000"); // N06→N07
    private static readonly Guid ME06 = new("dd000006-0000-0000-0000-000000000000"); // N07→N08

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
            Type = MapNodeType.Zone,
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
            Type = MapNodeType.Zone,
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
            Type = MapNodeType.Zone,
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
            Type = MapNodeType.Zone,
            Region = MapRegion.MountainsOfStrength,
            PositionX = 150, PositionY = 700,
            LevelRequirement = 3, RewardXp = 400,
            IsStartNode = false, IsHidden = false
        },
    ];

    public static IReadOnlyList<MapEdge> CreateMapEdges() =>
    [
        // Z02 Forest edges
        new MapEdge { Id = ME01, FromNodeId = N01, ToNodeId = N02, DistanceKm = 2, IsBidirectional = true },
        new MapEdge { Id = ME02, FromNodeId = N02, ToNodeId = N03, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME03, FromNodeId = N03, ToNodeId = N04, DistanceKm = 3, IsBidirectional = true },

        // Z03 Mountain edges
        new MapEdge { Id = ME04, FromNodeId = N05, ToNodeId = N06, DistanceKm = 2, IsBidirectional = true },
        new MapEdge { Id = ME05, FromNodeId = N06, ToNodeId = N07, DistanceKm = 2.5, IsBidirectional = true },
        new MapEdge { Id = ME06, FromNodeId = N07, ToNodeId = N08, DistanceKm = 3, IsBidirectional = true },
    ];
}
