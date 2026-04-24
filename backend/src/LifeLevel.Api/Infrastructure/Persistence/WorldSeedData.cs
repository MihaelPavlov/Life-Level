using System.Text.Json;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Enums;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Api.Infrastructure.Persistence;

/// <summary>
/// Deterministic seed data for the v3 World Map:
///   • 1 World
///   • 15 Regions (4 hand-authored hero regions + 11 templated)
///   • ~110 WorldZones (hero regions: 7-9 zones; templated: 7 zones, includes
///     2 branch zones per crossroads)
///   • ~130 WorldZoneEdges (intra-region linear + fork-and-rejoin + inter-region boss→entry)
///
/// Crossroads fork topology:
///   ... → Crossroads → [BranchA (easy), BranchB (hard)] → Rejoin → ...
///   Crossroads gets one edge to each branch; each branch rejoins the linear
///   chain via a zero-distance edge (see CreateEdges for details).
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
    // BranchOfName: when non-null, this zone is a branch of the zone in the
    // same region whose Name matches. Resolved at zone-creation time.
    // ChestRewardXp / ChestRewardDescription: populated only for Chest-type zones.
    // DungeonBonusXp / DungeonFloors: populated only for Dungeon-type zones.
    private sealed record ZoneSpec(
        string Name, string Emoji, WorldZoneType Type, double DistanceKm, int XpReward, string Description,
        string? BranchOfName = null,
        int? ChestRewardXp = null,
        string? ChestRewardDescription = null,
        int? DungeonBonusXp = null,
        IReadOnlyList<DungeonFloorSpec>? DungeonFloors = null);

    /// <summary>
    /// Floor definition for a Dungeon zone. One row per ordinal; at runtime the
    /// user clears them sequentially by logging workouts of the matching type.
    /// </summary>
    public sealed record DungeonFloorSpec(
        string Name, string Emoji, ActivityType ActivityType,
        DungeonFloorTargetKind TargetKind, double TargetValue);

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
            new("Whispering Grove",  "🌿", WorldZoneType.Entry,       0,   0,   "Where every journey begins. The grove welcomes new adventurers."),
            new("Dawn Camp",         "⛺", WorldZoneType.Standard,   3.0, 320,  "A warm camp at first light. Rest before the long run ahead."),
            new("Whispering Shrine", "🗝️", WorldZoneType.Chest,      2.0, 0,   "An old shrine left for wandering adventurers. Open its chest.",
                ChestRewardXp: 250, ChestRewardDescription: "A weathered chest left by forgotten pilgrims."),
            new("Misty Pine",        "🌲", WorldZoneType.Standard,   4.2, 420,  "Towering pines wrapped in mist. You are here."),
            new("Ember Forge",       "🏰", WorldZoneType.Standard,   5.0, 600,  "An ancient forge hidden deep in the forest."),
            new("Sunken Ruins",      "🏚️", WorldZoneType.Dungeon,    4.0, 0,   "Three crumbled trials guard the Warden's path.",
                DungeonBonusXp: 510,
                DungeonFloors:
                [
                    new("Running trial", "🏃", ActivityType.Running, DungeonFloorTargetKind.DistanceKm,     3.0),
                    new("Strength trial","🏋️", ActivityType.Gym,     DungeonFloorTargetKind.DurationMinutes, 30),
                    new("Balance trial", "🧘", ActivityType.Yoga,    DungeonFloorTargetKind.DurationMinutes, 15),
                ]),
            new("Twin Roads Fork",   "🔀", WorldZoneType.Crossroads, 2.0, 0,    "Two paths diverge. Choose wisely."),
            new("Valley Road",       "🌾", WorldZoneType.Standard,   8.0, 450,  "Easy route — scenic + longer.",  BranchOfName: "Twin Roads Fork"),
            new("Ruined Pass",       "🏚️", WorldZoneType.Standard,   5.0, 700,  "Shortcut — punishing but rich.", BranchOfName: "Twin Roads Fork"),
            new("Hollow Thicket",    "🍂", WorldZoneType.Standard,   4.5, 520,  "A shadowed thicket where wild things roam."),
            new("Forest Warden",     "🐺", WorldZoneType.Boss,       6.0, 1200, "The Warden stands between you and the Mountains."),
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
            new("Pearl Chest",          "💎", WorldZoneType.Chest,      2.5, 0,   "A pearl-inlaid chest nestled between the reefs.",
                ChestRewardXp: 280, ChestRewardDescription: "A pearl-inlaid reward hidden between the reefs."),
            new("Whispering Currents",  "🌊", WorldZoneType.Standard,   4.8, 480,  "Deep swells carry echoes from below."),
            new("Drowned Depths",       "🌀", WorldZoneType.Dungeon,    4.5, 0,   "A labyrinth of tide-carved halls beneath the surface.",
                DungeonBonusXp: 640,
                DungeonFloors:
                [
                    new("Deep swim",   "🏊", ActivityType.Swimming, DungeonFloorTargetKind.DistanceKm,     1.5),
                    new("Long ride",   "🚴", ActivityType.Cycling,  DungeonFloorTargetKind.DistanceKm,     10),
                    new("Still flow",  "🧘", ActivityType.Yoga,     DungeonFloorTargetKind.DurationMinutes, 20),
                ]),
            new("Sunken Temple",        "🔀", WorldZoneType.Crossroads, 3.0, 0,    "An ancient temple half-drowned at the fork of the sea."),
            new("Lagoon Drift",         "🐬", WorldZoneType.Standard,   5.5, 460,  "Easy tide — gentle currents.", BranchOfName: "Sunken Temple"),
            new("Abyssal Cleft",        "🌀", WorldZoneType.Standard,   3.5, 760,  "Hard dive — icy pressure.",    BranchOfName: "Sunken Temple"),
            new("Tide Sovereign",       "🐙", WorldZoneType.Boss,       6.5, 1400, "The crown of the deep waits in the storm's eye."),
        ],
        [new RegionPin("+10% STA", "region bonus"), new RegionPin("Daily XP", "")]);

    // Hero region 3 — Mountains of Strength.
    private static readonly RegionSpec Mountains = new(
        R03, "Mountains of Strength", "⛰️", RegionTheme.Mountain, 15, 3,
        "Stone Titan",
        "Jagged peaks conquered by gym sessions and climbs. Reward: +15% STR gain.",
        [
            new("Basecamp Trail",        "⛺", WorldZoneType.Entry,       0,   0,   "The last safe camp before the climb begins."),
            new("Switchback Ridge",      "🪨", WorldZoneType.Standard,   4.0, 400,  "A punishing set of switchbacks. Every step is earned."),
            new("Hidden Cairn",          "⛰️", WorldZoneType.Chest,      2.8, 0,   "A stone cairn hides a climber's hoard.",
                ChestRewardXp: 320, ChestRewardDescription: "A stone cairn hides a forgotten climber's hoard."),
            new("Iron Pass",             "🔀", WorldZoneType.Crossroads, 2.5, 0,    "The pass splits around a fallen titan's bones."),
            new("Shepherd's Switchback", "🐐", WorldZoneType.Standard,   7.0, 520,  "Easy ascent — winding mule path.", BranchOfName: "Iron Pass"),
            new("Cliff Face",            "🧗", WorldZoneType.Standard,   4.2, 820,  "Hard climb — sheer granite.",       BranchOfName: "Iron Pass"),
            new("Summit Approach",       "🏔️", WorldZoneType.Standard,   5.5, 620,  "Thin air, hard wind. The summit is close."),
            new("Titan's Crypt",         "🪨", WorldZoneType.Dungeon,    5.0, 0,   "Three strength trials guard the titan's hall.",
                DungeonBonusXp: 850,
                DungeonFloors:
                [
                    new("Climb trial",  "🧗",  ActivityType.Climbing, DungeonFloorTargetKind.DurationMinutes, 30),
                    new("Hike trial",   "🥾",  ActivityType.Hiking,   DungeonFloorTargetKind.DistanceKm,      5),
                    new("Iron trial",   "🏋️", ActivityType.Gym,      DungeonFloorTargetKind.DurationMinutes, 45),
                ]),
            new("Stone Titan",           "🗿", WorldZoneType.Boss,       7.0, 1600, "The mountain wakes. The titan will not step aside."),
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
            new("Ember Vault",     "🔥", WorldZoneType.Chest,      3.2, 0,   "Sealed against the eruption — its contents survived.",
                ChestRewardXp: 400, ChestRewardDescription: "A vault sealed before the eruption; still intact."),
            new("Lava Chasm",      "🔀", WorldZoneType.Crossroads, 3.0, 0,    "A glowing chasm splits the path in two."),
            new("Cooled Flow",     "🪨", WorldZoneType.Standard,   6.5, 620,  "Easy walk — hardened magma.",   BranchOfName: "Lava Chasm"),
            new("Inferno Bridge",  "🌋", WorldZoneType.Standard,   3.8, 920,  "Hard crossing — molten lake.",  BranchOfName: "Lava Chasm"),
            new("Molten Spire",    "🗼", WorldZoneType.Standard,   5.8, 680,  "A spire of living rock climbing from the flames."),
            new("Magma Labyrinth", "🔥", WorldZoneType.Dungeon,    5.5, 0,   "A maze of molten passages. Clear its trials for glory.",
                DungeonBonusXp: 1100,
                DungeonFloors:
                [
                    new("Ember sprint", "🏃",  ActivityType.Running,  DungeonFloorTargetKind.DistanceKm,      5),
                    new("Forge trial",  "🏋️", ActivityType.Gym,      DungeonFloorTargetKind.DurationMinutes, 40),
                    new("Cooling swim", "🏊",  ActivityType.Swimming, DungeonFloorTargetKind.DistanceKm,      1),
                ]),
            new("Molten King",     "👑", WorldZoneType.Boss,       8.0, 1800, "The caldera's crown awaits — and it burns."),
        ],
        [new RegionPin("+20% ALL", "region bonus"), new RegionPin("Endgame", "")]);

    // Templated regions 5..15. Theme rotation, escalating level requirements,
    // 7 zones each (Entry + Standard + Crossroads + 2 branches + Standard + Boss).
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

    // Branch XP/km: shared base from slot 2 of the template with +/- difficulty tilt.
    private static int TemplateBranchXp(int levelReq, bool hard)
    {
        int baseXp = TemplateXp(levelReq, WorldZoneType.Standard, 2);
        return hard ? (int)Math.Round(baseXp * 1.55) : (int)Math.Round(baseXp * 0.95);
    }

    private static IReadOnlyList<ZoneSpec> TemplateZones(TemplateInput t)
    {
        string themeWord = t.Theme.ToString();
        const string crossroadsName = "Broken Fork";
        double branchBaseKm = TemplateKm(t.LevelReq, 2);
        double easyKm  = Math.Round(branchBaseKm * 1.4, 1);
        double hardKm  = Math.Round(branchBaseKm * 0.7, 1);

        // Templated chest: scaled XP `200 + levelReq * 4`, placed right after
        // the entry zone so every region has an early reward to find.
        int chestXp = 200 + t.LevelReq * 4;

        // Templated dungeon: bonus XP `400 + levelReq * 15`, three rotating
        // floors (Running → Gym → Yoga) — the shape matches the mockup.
        int dungeonBonusXp = 400 + t.LevelReq * 15;
        double runKm = Math.Round(2.5 + t.LevelReq * 0.05, 1);
        int gymMin   = 25 + (int)Math.Round(t.LevelReq * 0.3);
        int yogaMin  = 12 + (int)Math.Round(t.LevelReq * 0.15);

        return
        [
            new($"{t.Name} Gate",       "🚪", WorldZoneType.Entry,       0,                              0,                           $"The threshold of {t.Name}. Step through at your own risk."),
            new($"{t.Name} Hoard",      "🗝️", WorldZoneType.Chest,      Math.Max(1.5, TemplateKm(t.LevelReq, 1) - 1.5), 0,          $"A hoard left by the last traveller to cross {t.Name}.",
                ChestRewardXp: chestXp, ChestRewardDescription: $"A hoard left by the last traveller to brave {t.Name}."),
            new($"{themeWord} Expanse", "🌫️", WorldZoneType.Standard,   TemplateKm(t.LevelReq, 1),     TemplateXp(t.LevelReq, WorldZoneType.Standard, 1), $"A vast stretch of {themeWord.ToLowerInvariant()} pulling you onward."),
            new(crossroadsName,          "🔀", WorldZoneType.Crossroads, Math.Max(1.0, TemplateKm(t.LevelReq, 2) - 1), 0,            $"An old ruin splits the path of {t.Name}."),
            new($"{t.Name} Lowroad",    "🌾", WorldZoneType.Standard,   easyKm,                        TemplateBranchXp(t.LevelReq, false), $"Easy road — longer but forgiving across {t.Name}.", BranchOfName: crossroadsName),
            new($"{t.Name} Highroad",   "⛰️", WorldZoneType.Standard,   hardKm,                        TemplateBranchXp(t.LevelReq, true),  $"Hard road — short but brutal across {t.Name}.",     BranchOfName: crossroadsName),
            new($"{t.Name} Heart",      "✨", WorldZoneType.Standard,   TemplateKm(t.LevelReq, 3),     TemplateXp(t.LevelReq, WorldZoneType.Standard, 3), $"The beating core of {t.Name}, thick with XP."),
            new($"{t.Name} Vaults",     "🏚️", WorldZoneType.Dungeon,   Math.Max(2.0, TemplateKm(t.LevelReq, 3) - 1), 0,             $"Sealed vaults beneath {t.Name}. Three trials inside.",
                DungeonBonusXp: dungeonBonusXp,
                DungeonFloors:
                [
                    new("Running trial",  "🏃",  ActivityType.Running, DungeonFloorTargetKind.DistanceKm,      runKm),
                    new("Strength trial", "🏋️", ActivityType.Gym,     DungeonFloorTargetKind.DurationMinutes, gymMin),
                    new("Balance trial",  "🧘",  ActivityType.Yoga,    DungeonFloorTargetKind.DurationMinutes, yogaMin),
                ]),
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
            bool isStarter = regionIdx == 0;

            // Compute tier per slot. Branches at slot S share the tier of the
            // previous non-branch slot + 1. Post-branch zones get bumped by 1
            // after each branch pair to preserve the original linear-chain tier
            // for Entry + Boss.
            var tiers = ComputeTiers(region.Zones);

            // Resolve BranchOfName → BranchOfId within this region.
            var byName = new Dictionary<string, Guid>(StringComparer.OrdinalIgnoreCase);
            for (int slot = 0; slot < region.Zones.Count; slot++)
            {
                byName[region.Zones[slot].Name] = ZoneId(regionIdx + 1, slot + 1);
            }

            for (int slot = 0; slot < region.Zones.Count; slot++)
            {
                var z = region.Zones[slot];
                Guid? branchOf = null;
                if (!string.IsNullOrEmpty(z.BranchOfName)
                    && byName.TryGetValue(z.BranchOfName!, out var crossroadsId))
                {
                    branchOf = crossroadsId;
                }

                list.Add(new WorldZoneEntity
                {
                    Id                     = ZoneId(regionIdx + 1, slot + 1),
                    RegionId               = region.Id,
                    Name                   = z.Name,
                    Description            = z.Description,
                    Emoji                  = z.Emoji,
                    Tier                   = tiers[slot],
                    LevelRequirement       = region.LevelReq,
                    XpReward               = z.XpReward,
                    DistanceKm             = z.DistanceKm,
                    IsStartZone            = isStarter && z.Type == WorldZoneType.Entry,
                    IsBoss                 = z.Type == WorldZoneType.Boss,
                    Type                   = z.Type,
                    BranchOfId             = branchOf,
                    ChestRewardXp          = z.Type == WorldZoneType.Chest ? z.ChestRewardXp : null,
                    ChestRewardDescription = z.Type == WorldZoneType.Chest ? z.ChestRewardDescription : null,
                    DungeonBonusXp         = z.Type == WorldZoneType.Dungeon ? z.DungeonBonusXp : null,
                });
            }
        }
        return list;
    }

    /// <summary>
    /// Emits <see cref="WorldZoneDungeonFloor"/> rows for every Dungeon-typed
    /// zone whose spec carries a <c>DungeonFloors</c> list. One row per
    /// ordinal (1..N). Must be called after <see cref="CreateZones"/> since
    /// it uses the same zone-id encoding.
    /// </summary>
    public static IReadOnlyList<WorldZoneDungeonFloor> CreateDungeonFloors()
    {
        var list = new List<WorldZoneDungeonFloor>();
        for (int regionIdx = 0; regionIdx < Regions.Count; regionIdx++)
        {
            var region = Regions[regionIdx];
            for (int slot = 0; slot < region.Zones.Count; slot++)
            {
                var z = region.Zones[slot];
                if (z.Type != WorldZoneType.Dungeon) continue;
                if (z.DungeonFloors == null) continue;

                var zoneId = ZoneId(regionIdx + 1, slot + 1);
                for (int f = 0; f < z.DungeonFloors.Count; f++)
                {
                    var floorSpec = z.DungeonFloors[f];
                    list.Add(new WorldZoneDungeonFloor
                    {
                        Id           = DungeonFloorId(regionIdx + 1, slot + 1, f + 1),
                        WorldZoneId  = zoneId,
                        Ordinal      = f + 1,
                        ActivityType = floorSpec.ActivityType,
                        TargetKind   = floorSpec.TargetKind,
                        TargetValue  = floorSpec.TargetValue,
                        Name         = floorSpec.Name,
                        Emoji        = floorSpec.Emoji,
                    });
                }
            }
        }
        return list;
    }

    // Stable, deterministic ids so reseeds don't keep inflating the table.
    private static Guid DungeonFloorId(int regionIdx, int slot, int ordinal)
        => new($"df00{regionIdx:x2}{slot:x2}-{ordinal:x4}-0000-0000-000000000000");

    /// <summary>
    /// Walk the zone list and assign each a tier. A branch zone shares a tier
    /// with its sibling (both tier = crossroads.Tier + 1). Post-branch zones
    /// resume at crossroads.Tier + 2. Plain linear zones increment by 1.
    /// </summary>
    private static int[] ComputeTiers(IReadOnlyList<ZoneSpec> zones)
    {
        var tiers = new int[zones.Count];
        int nextTier = 1;
        int? crossroadsTier = null;

        for (int i = 0; i < zones.Count; i++)
        {
            var z = zones[i];
            if (z.BranchOfName != null)
            {
                // Both branches share crossroads.Tier + 1. No tier advance
                // between siblings.
                tiers[i] = (crossroadsTier ?? nextTier - 1) + 1;
                // After emitting the final branch, the next zone should be
                // crossroads.Tier + 2. Do NOT advance nextTier on each branch —
                // we'll set it when we leave the branch block.
                bool nextIsBranch = (i + 1 < zones.Count) && zones[i + 1].BranchOfName != null;
                if (!nextIsBranch)
                {
                    nextTier = (crossroadsTier ?? tiers[i]) + 2;
                    crossroadsTier = null;
                }
                continue;
            }

            tiers[i] = nextTier++;
            if (z.Type == WorldZoneType.Crossroads)
            {
                crossroadsTier = tiers[i];
            }
        }

        return tiers;
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

            // Walk the zone list in order. Non-branch consecutive pairs get a
            // linear bidirectional edge. Crossroads → branch(es) → rejoin forms
            // a fork where the crossroads linear edge to the rejoin is replaced
            // by two branch edges + two 0-km rejoin edges.
            int i = 0;
            while (i < count - 1)
            {
                var current = region.Zones[i];
                bool currentIsBranch = current.BranchOfName != null;
                var next = region.Zones[i + 1];
                bool nextIsBranch = next.BranchOfName != null;

                if (current.Type == WorldZoneType.Crossroads && nextIsBranch)
                {
                    // Collect the contiguous run of branch siblings (expect 2).
                    int firstBranch = i + 1;
                    int lastBranch = firstBranch;
                    while (lastBranch + 1 < count && region.Zones[lastBranch + 1].BranchOfName != null)
                        lastBranch++;

                    // Crossroads → each branch. Edge distance = branch.DistanceKm.
                    for (int b = firstBranch; b <= lastBranch; b++)
                    {
                        var branchZone = region.Zones[b];
                        list.Add(new WorldZoneEdge
                        {
                            Id              = EdgeId(n++),
                            FromZoneId      = ZoneId(regionIdx + 1, i + 1),
                            ToZoneId        = ZoneId(regionIdx + 1, b + 1),
                            DistanceKm      = branchZone.DistanceKm > 0 ? branchZone.DistanceKm : 1.0,
                            IsBidirectional = false,
                        });
                    }

                    // Rejoin is the first non-branch zone after the branch run.
                    int rejoinSlot = lastBranch + 1;
                    if (rejoinSlot < count)
                    {
                        var rejoinZone = region.Zones[rejoinSlot];
                        // Use the rejoin zone's own DistanceKm as the edge
                        // cost so the journey banner shows a real progress
                        // bar (e.g. Valley Road → Hollow Thicket = 4.5 km),
                        // not "0.0 / 0.0 km".
                        var rejoinEdgeKm = rejoinZone.DistanceKm > 0
                            ? rejoinZone.DistanceKm
                            : 1.0;
                        for (int b = firstBranch; b <= lastBranch; b++)
                        {
                            list.Add(new WorldZoneEdge
                            {
                                Id              = EdgeId(n++),
                                FromZoneId      = ZoneId(regionIdx + 1, b + 1),
                                ToZoneId        = ZoneId(regionIdx + 1, rejoinSlot + 1),
                                DistanceKm      = rejoinEdgeKm,
                                IsBidirectional = false,
                            });
                        }
                    }

                    // Advance past the whole fork block. Next loop iteration
                    // starts at the rejoin zone (which will then emit normal
                    // linear edges to its successors).
                    i = rejoinSlot;
                    continue;
                }

                if (currentIsBranch)
                {
                    // Skip — branch edges are authored by the crossroads block above.
                    // (This case only triggers when a branch is followed by another
                    // non-branch zone that isn't the rejoin — shouldn't happen with
                    // the current seed, but we guard against it.)
                    i++;
                    continue;
                }

                if (nextIsBranch)
                {
                    // Non-crossroads → branch: nothing to emit here; the branch
                    // edges come from the crossroads pass above.
                    i++;
                    continue;
                }

                // Normal linear pair: emit bidirectional edge.
                list.Add(new WorldZoneEdge
                {
                    Id              = EdgeId(n++),
                    FromZoneId      = ZoneId(regionIdx + 1, i + 1),
                    ToZoneId        = ZoneId(regionIdx + 1, i + 2),
                    DistanceKm      = next.DistanceKm > 0 ? next.DistanceKm : 1.0,
                    IsBidirectional = true,
                });
                i++;
            }
        }

        // Inter-region edges: boss of region N → entry of region N+1 (one-way,
        // unlocks on boss defeat). DistanceKm=0 so the user teleports once the
        // boss is cleared — enforcement is done elsewhere (level gate).
        for (int regionIdx = 0; regionIdx < Regions.Count - 1; regionIdx++)
        {
            var fromRegion = Regions[regionIdx];
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
