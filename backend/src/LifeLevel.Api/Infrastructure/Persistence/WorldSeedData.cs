using System.Text.Json;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Api.Infrastructure.Persistence;

/// <summary>
/// Deterministic seed data for the v3 World Map:
///   • 1 World
///   • 15 Regions (4 hand-authored hero regions + 11 templated)
///   • ~80 WorldZones (hero regions: 5–7 zones; templated: 5 zones)
///   • ~90 WorldZoneEdges (intra-region path + inter-region boss→entry)
///
/// Regions 5..15 are templated so the seed stays readable; we can always
/// hand-author more later by inserting them into the list.
///
/// ID-prefix encoding (16-bit slot per entity kind):
///   c1_rr___ — Regions                rr = chapter index (1..15)
///   aa_rrzz  — WorldZones             rr = region index, zz = zone slot
///   bb____e_ — WorldZoneEdges         monotonically numbered
/// </summary>
public static class WorldSeedData
{
    public static readonly Guid WorldId = new("cc000001-0000-0000-0000-000000000000");

    // ── Region IDs (15) ──────────────────────────────────────────────────────
    private static readonly Guid R01 = Rid(1);
    private static readonly Guid R02 = Rid(2);
    private static readonly Guid R03 = Rid(3);
    private static readonly Guid R04 = Rid(4);
    private static readonly Guid R05 = Rid(5);
    private static readonly Guid R06 = Rid(6);
    private static readonly Guid R07 = Rid(7);
    private static readonly Guid R08 = Rid(8);
    private static readonly Guid R09 = Rid(9);
    private static readonly Guid R10 = Rid(10);
    private static readonly Guid R11 = Rid(11);
    private static readonly Guid R12 = Rid(12);
    private static readonly Guid R13 = Rid(13);
    private static readonly Guid R14 = Rid(14);
    private static readonly Guid R15 = Rid(15);

    private static Guid Rid(int chapter) => new($"c100{chapter:x4}-0000-0000-0000-000000000000");
    private static Guid ZoneId(int regionIdx, int slot) => new($"aa00{regionIdx:x2}{slot:x2}-0000-0000-0000-000000000000");
    private static Guid EdgeId(int n) => new($"bb00{n:x4}-0000-0000-0000-000000000000");

    // ── Region & zone specs ──────────────────────────────────────────────────
    private sealed record ZoneSpec(
        string Name, string Emoji, WorldZoneType Type, double DistanceKm, int XpReward, string Description);

    private sealed record RegionSpec(
        Guid Id, string Name, string Emoji, RegionTheme Theme, int LevelReq,
        int ChapterIndex, string BossName, string Lore,
        IReadOnlyList<ZoneSpec> Zones, IReadOnlyList<RegionPin> Pins);

    // Hero region 1 — Forest of Endurance (Chapter 1, starter).
    private static readonly RegionSpec Forest = new(
        R01, "Forest of Endurance", "🌲", RegionTheme.Forest, 1, 1,
        "Forest Warden",
        "Endless woodlands that reward every km logged. Run and cycle to carve your path.",
        [
            new("Whispering Grove", "🌿", WorldZoneType.Entry,       0,   0,   "Where every journey begins. The grove welcomes new adventurers."),
            new("Dawn Camp",        "⛺", WorldZoneType.Standard,   3.0, 320,  "A warm camp at first light. Rest before the long run ahead."),
            new("Misty Pine",       "🌲", WorldZoneType.Standard,   4.2, 420,  "Towering pines wrapped in mist. You are here."),
            new("Ember Forge",      "🏰", WorldZoneType.Standard,   5.0, 600,  "An ancient forge hidden deep in the forest."),
            new("Twin Roads Fork",  "🔀", WorldZoneType.Crossroads, 2.0, 0,    "Two paths diverge. Choose wisely."),
            new("Hollow Thicket",   "🍂", WorldZoneType.Standard,   4.5, 520,  "A shadowed thicket where wild things roam."),
            new("Forest Warden",    "🐺", WorldZoneType.Boss,       6.0, 1200, "The Warden stands between you and the Mountains."),
        ],
        [new RegionPin("+10% END", "region bonus"), new RegionPin("Starter", "")]);

    // Hero region 2 — Ocean of Balance.
    private static readonly RegionSpec Ocean = new(
        R02, "Ocean of Balance", "🌊", RegionTheme.Ocean, 8, 2,
        "Tide Sovereign",
        "Tidal islands linked by swims and yoga flows. Revisit for daily XP.",
        [
            new("Tidepool Landing",     "🐚", WorldZoneType.Entry,       0,   0,   "The shore where the first tides welcome you."),
            new("Coral Shallows",       "🪸", WorldZoneType.Standard,   3.5, 360,  "Gentle currents teach your breath a new rhythm."),
            new("Whispering Currents",  "🌊", WorldZoneType.Standard,   4.8, 480,  "Deep swells carry echoes from below."),
            new("Sunken Temple",        "🔀", WorldZoneType.Crossroads, 3.0, 0,    "An ancient temple half-drowned at the fork of the sea."),
            new("Tide Sovereign",       "🐙", WorldZoneType.Boss,       6.5, 1400, "The crown of the deep waits in the storm's eye."),
        ],
        [new RegionPin("+10% STA", "region bonus"), new RegionPin("Daily XP", "")]);

    // Hero region 3 — Mountains of Strength.
    private static readonly RegionSpec Mountains = new(
        R03, "Mountains of Strength", "⛰️", RegionTheme.Mountain, 15, 3,
        "Stone Titan",
        "Jagged peaks conquered by gym sessions and climbs. Reward: +15% STR gain.",
        [
            new("Basecamp Trail",   "⛺", WorldZoneType.Entry,       0,   0,   "The last safe camp before the climb begins."),
            new("Switchback Ridge", "🪨", WorldZoneType.Standard,   4.0, 400,  "A punishing set of switchbacks. Every step is earned."),
            new("Iron Pass",        "🔀", WorldZoneType.Crossroads, 2.5, 0,    "The pass splits around a fallen titan's bones."),
            new("Summit Approach",  "🏔️", WorldZoneType.Standard,   5.5, 620,  "Thin air, hard wind. The summit is close."),
            new("Stone Titan",      "🗿", WorldZoneType.Boss,       7.0, 1600, "The mountain wakes. The titan will not step aside."),
        ],
        [new RegionPin("+15% STR", "region bonus"), new RegionPin("Gym", "")]);

    // Hero region 4 — Ashen Caldera.
    private static readonly RegionSpec Caldera = new(
        R04, "Ashen Caldera", "🌋", RegionTheme.Volcano, 25, 4,
        "Molten King",
        "Endgame volcanic region. HIIT + cardio unlock legendary loot.",
        [
            new("Ash Outpost",     "🏚️", WorldZoneType.Entry,       0,   0,   "The last standing outpost before the caldera's heat."),
            new("Obsidian Flats",  "🪨", WorldZoneType.Standard,   4.5, 520,  "Black glass underfoot. Every breath tastes of sulfur."),
            new("Lava Chasm",      "🔀", WorldZoneType.Crossroads, 3.0, 0,    "A glowing chasm splits the path in two."),
            new("Molten Spire",    "🗼", WorldZoneType.Standard,   5.8, 680,  "A spire of living rock climbing from the flames."),
            new("Molten King",     "👑", WorldZoneType.Boss,       8.0, 1800, "The caldera's crown awaits — and it burns."),
        ],
        [new RegionPin("+20% ALL", "region bonus"), new RegionPin("Endgame", "")]);

    // Templated regions 5..15. Theme rotation, escalating level requirements,
    // 5 zones each (Entry + Standard + Crossroads + Standard + Boss).
    private sealed record TemplateInput(
        Guid Id, string Name, string Emoji, RegionTheme Theme, int LevelReq,
        int ChapterIndex, string BossName, string Lore);

    private static readonly IReadOnlyList<TemplateInput> TemplatedRegions =
    [
        new(R05, "Frostspire Tundra",   "❄️", RegionTheme.Frost,    32,  5, "Hoarfrost Queen",    "Wind-carved ice fields where only the relentless keep warm."),
        new(R06, "Sunscorch Dunes",     "🏜️", RegionTheme.Desert,   38,  6, "Dune Pharaoh",       "Dunes that swallow footprints and memories alike."),
        new(R07, "Shadewood Deep",      "🌳", RegionTheme.Forest,   44,  7, "Bramble Lord",       "A forest so old the trees forgot the sun."),
        new(R08, "Moonlit Reef",        "🌙", RegionTheme.Ocean,    50,  8, "Pearl Leviathan",    "A reef that glows beneath the moon and hungers beneath the tide."),
        new(R09, "Thunderpeak Range",   "⚡", RegionTheme.Mountain, 56,  9, "Storm Sovereign",    "Summits where the sky itself fights back."),
        new(R10, "Emberfall Crater",    "🔥", RegionTheme.Volcano,  62, 10, "Cinder Archon",      "A crater still raining its first eruption."),
        new(R11, "Glacier Abyss",       "🧊", RegionTheme.Frost,    68, 11, "Deepfrost Wyrm",     "Ice so old it has forgotten how to melt."),
        new(R12, "Mirage Wastes",       "☀️", RegionTheme.Desert,   72, 12, "Sand Kaiser",        "A waste where every horizon is a trick of the light."),
        new(R13, "Verdant Spine",       "🌿", RegionTheme.Forest,   76, 13, "Thornwarden",        "A ridge of living jungle rising into the clouds."),
        new(R14, "Abyssal Trench",      "🌀", RegionTheme.Ocean,    80, 14, "Maw of the Deep",    "A trench without light, without silence, without end."),
        new(R15, "Apex Caldera",        "🌋", RegionTheme.Volcano,  85, 15, "Worldflame",         "The last fire at the top of the world."),
    ];

    // Scaling helpers for templated zones.
    private static double TemplateKm(int levelReq, int slot) => Math.Round(3.0 + slot * 1.2 + levelReq * 0.02, 1);
    private static int TemplateXp(int levelReq, WorldZoneType type, int slot)
    {
        if (type == WorldZoneType.Entry) return 0;
        if (type == WorldZoneType.Crossroads) return 0;
        int baseXp = 300 + levelReq * 10 + slot * 80;
        if (type == WorldZoneType.Boss) return baseXp * 2 + 600;
        return baseXp;
    }

    private static IReadOnlyList<ZoneSpec> TemplateZones(TemplateInput t)
    {
        string themeWord = t.Theme.ToString();
        return
        [
            new($"{t.Name} Gate",       "🚪", WorldZoneType.Entry,       0,                              0,                           $"The threshold of {t.Name}. Step through at your own risk."),
            new($"{themeWord} Expanse", "🌫️", WorldZoneType.Standard,   TemplateKm(t.LevelReq, 1),     TemplateXp(t.LevelReq, WorldZoneType.Standard, 1), $"A vast stretch of {themeWord.ToLowerInvariant()} pulling you onward."),
            new("Broken Fork",          "🔀", WorldZoneType.Crossroads, TemplateKm(t.LevelReq, 2) - 1, 0,                           $"An old ruin splits the path of {t.Name}."),
            new($"{t.Name} Heart",      "✨", WorldZoneType.Standard,   TemplateKm(t.LevelReq, 3),     TemplateXp(t.LevelReq, WorldZoneType.Standard, 3), $"The beating core of {t.Name}, thick with XP."),
            new(t.BossName,             "👹", WorldZoneType.Boss,       TemplateKm(t.LevelReq, 4) + 1, TemplateXp(t.LevelReq, WorldZoneType.Boss,     4), $"The champion of {t.Name} stands between you and the next chapter."),
        ];
    }

    private static RegionSpec Templated(TemplateInput t)
        => new(t.Id, t.Name, t.Emoji, t.Theme, t.LevelReq, t.ChapterIndex, t.BossName, t.Lore,
               TemplateZones(t), []);

    private static IReadOnlyList<RegionSpec> Regions => _regions ??= BuildRegions();
    private static IReadOnlyList<RegionSpec>? _regions;

    private static IReadOnlyList<RegionSpec> BuildRegions()
    {
        var list = new List<RegionSpec> { Forest, Ocean, Mountains, Caldera };
        list.AddRange(TemplatedRegions.Select(Templated));
        return list;
    }

    // ── Factories ────────────────────────────────────────────────────────────
    public static World CreateWorld() => new()
    {
        Id = WorldId,
        Name = "World v1",
        IsActive = true,
        CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
    };

    public static IReadOnlyList<Region> CreateRegions(Guid worldId)
    {
        var list = new List<Region>();
        foreach (var spec in Regions)
        {
            list.Add(new Region
            {
                Id               = spec.Id,
                WorldId          = worldId,
                Name             = spec.Name,
                Emoji            = spec.Emoji,
                Theme            = spec.Theme,
                ChapterIndex     = spec.ChapterIndex,
                LevelRequirement = spec.LevelReq,
                Lore             = spec.Lore,
                BossName         = spec.BossName,
                BossStatus       = RegionBossStatus.Locked,
                DefaultStatus    = spec.ChapterIndex == 1 ? RegionStatus.Active : RegionStatus.Locked,
                PinsJson         = spec.Pins.Count == 0 ? "[]" : JsonSerializer.Serialize(spec.Pins),
            });
        }
        return list;
    }

    public static IReadOnlyList<WorldZoneEntity> CreateZones()
    {
        var list = new List<WorldZoneEntity>();
        for (int regionIdx = 0; regionIdx < Regions.Count; regionIdx++)
        {
            var region = Regions[regionIdx];
            int tier = 1;
            bool isStarter = regionIdx == 0;
            for (int slot = 0; slot < region.Zones.Count; slot++, tier++)
            {
                var z = region.Zones[slot];
                list.Add(new WorldZoneEntity
                {
                    Id               = ZoneId(regionIdx + 1, slot + 1),
                    RegionId         = region.Id,
                    Name             = z.Name,
                    Description      = z.Description,
                    Emoji            = z.Emoji,
                    Tier             = tier,
                    LevelRequirement = region.LevelReq + (slot > 0 ? 0 : 0), // flat per-region; designed to match the region gate
                    XpReward         = z.XpReward,
                    DistanceKm       = z.DistanceKm,
                    IsStartZone      = isStarter && z.Type == WorldZoneType.Entry,
                    IsBoss           = z.Type == WorldZoneType.Boss,
                    Type             = z.Type,
                });
            }
        }
        return list;
    }

    public static IReadOnlyList<WorldZoneEdge> CreateEdges()
    {
        var list = new List<WorldZoneEdge>();
        int n = 1;

        for (int regionIdx = 0; regionIdx < Regions.Count; regionIdx++)
        {
            var region = Regions[regionIdx];
            int count = region.Zones.Count;
            if (count < 2) continue;

            // Linear chain (bidirectional) Entry -> slot2 -> ... -> Boss.
            for (int slot = 0; slot < count - 1; slot++)
            {
                var nextZone = region.Zones[slot + 1];
                list.Add(new WorldZoneEdge
                {
                    Id              = EdgeId(n++),
                    FromZoneId      = ZoneId(regionIdx + 1, slot + 1),
                    ToZoneId        = ZoneId(regionIdx + 1, slot + 2),
                    // Edge cost = destination zone's DistanceKm (entry cost).
                    DistanceKm      = nextZone.DistanceKm > 0 ? nextZone.DistanceKm : 1.0,
                    IsBidirectional = true,
                });
            }

            // Add a secondary crossroads branch: for any Crossroads slot, add
            // an edge back to the previous-previous zone to create a loop
            // (visualizes as a fork).
            for (int slot = 0; slot < count; slot++)
            {
                if (region.Zones[slot].Type != WorldZoneType.Crossroads) continue;
                // Target the penultimate standard zone if available (slot-2).
                int targetSlot = slot >= 2 ? slot - 2 : -1;
                if (targetSlot < 0 || targetSlot >= count) continue;
                list.Add(new WorldZoneEdge
                {
                    Id              = EdgeId(n++),
                    FromZoneId      = ZoneId(regionIdx + 1, slot + 1),
                    ToZoneId        = ZoneId(regionIdx + 1, targetSlot + 1),
                    DistanceKm      = 2.0,
                    IsBidirectional = true,
                });
            }
        }

        // Inter-region edges: boss of region N → entry of region N+1 (one-way,
        // unlocks on boss defeat). DistanceKm=0 so the user teleports once the
        // boss is cleared — enforcement is done elsewhere (level gate).
        for (int regionIdx = 0; regionIdx < Regions.Count - 1; regionIdx++)
        {
            var fromRegion = Regions[regionIdx];
            var toRegion = Regions[regionIdx + 1];
            var fromBossSlot = fromRegion.Zones.Count; // last slot (1-based)
            var toEntrySlot = 1;
            list.Add(new WorldZoneEdge
            {
                Id              = EdgeId(n++),
                FromZoneId      = ZoneId(regionIdx + 1, fromBossSlot),
                ToZoneId        = ZoneId(regionIdx + 2, toEntrySlot),
                DistanceKm      = 0,
                IsBidirectional = false,
            });
        }

        return list;
    }

    /// <summary>
    /// Seeds one start MapNode per WorldZone so the local-map initializer
    /// (MapService.InitializeUserProgressAsync) can place a user into any
    /// zone without crashing. The v3 map redesign drives travel via
    /// WorldZoneEdges, so a minimal local graph is sufficient.
    /// </summary>
    public static IReadOnlyList<MapNode> CreateMapStartNodes()
    {
        var list = new List<MapNode>();
        for (int regionIdx = 0; regionIdx < Regions.Count; regionIdx++)
        {
            var region = Regions[regionIdx];
            for (int slot = 0; slot < region.Zones.Count; slot++)
            {
                var zone = region.Zones[slot];
                list.Add(new MapNode
                {
                    Id = new($"dd00{(regionIdx + 1):x2}{(slot + 1):x2}-0000-0000-0000-000000000000"),
                    Name = zone.Name,
                    Description = zone.Description,
                    Icon = zone.Emoji,
                    Type = MapNodeType.Zone,
                    Region = MapRegionFromTheme(region.Theme),
                    PositionX = 0,
                    PositionY = 0,
                    LevelRequirement = region.LevelReq,
                    RewardXp = 0,
                    IsStartNode = true,
                    IsHidden = false,
                    WorldZoneId = ZoneId(regionIdx + 1, slot + 1),
                });
            }
        }
        return list;
    }

    private static MapRegion MapRegionFromTheme(RegionTheme theme) => theme switch
    {
        RegionTheme.Forest   => MapRegion.ForestOfEndurance,
        RegionTheme.Mountain => MapRegion.MountainsOfStrength,
        RegionTheme.Ocean    => MapRegion.OceanOfBalance,
        RegionTheme.Frost    => MapRegion.SnowPeaks,
        RegionTheme.Volcano  => MapRegion.Ashfield,
        RegionTheme.Desert   => MapRegion.Desert,
        _                    => MapRegion.Ashfield,
    };
}
