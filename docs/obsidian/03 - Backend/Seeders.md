---
tags: [lifelevel, backend]
aliases: [WorldSeeder, ItemSeeder, AchievementSeeder, TitleSeeder]
---
# Seeders

> Idempotent seed-data classes that populate the database on first startup. All live in `LifeLevel.Api` (composition root) because they span multiple modules' entities.

All seeders follow the pattern: `if (await db.X.AnyAsync()) return;` — safe to run every boot.

## WorldSeeder

**Location:** `backend/src/LifeLevel.Api/Infrastructure/Persistence/WorldSeeder.cs`

Populates the entire game world:

1. **1 `World`** (global).
2. **3+ `WorldZones`** — Forest of Endurance, Mountains of Strength, Ocean of Balance (and more per CLAUDE.md progression).
3. **`WorldZoneEdges`** — directed zone adjacency graph.
4. **`MapNodes`** per zone — types: `Boss`, `Chest`, `DungeonPortal`, `Crossroads`, plus one `IsStartNode` per zone.
5. **`MapEdges`** — directed node connectivity with `DistanceKm`.
6. **`Bosses`** — 1:1 with Boss-type nodes. Attributes: Name, Icon, MaxHp, RewardXp, `TimerDays`, `IsMini`.
7. **`Chests`** — 1:1 with Chest-type nodes.
8. **`DungeonPortals`** + **`DungeonFloors`** — one portal → N floors.
9. **`Crossroads`** + **`CrossroadsPaths`** — one crossroads → multiple exit paths (`LeadsToNodeId`).

Stays in Api because it touches entities from Map, WorldZone, Adventure.Encounters, and Adventure.Dungeons modules.

## ItemSeeder

**Location:** `backend/src/LifeLevel.Api/Infrastructure/Persistence/ItemSeeder.cs`

Two phases:

```csharp
await itemSeeder.SeedCatalogAsync();   // creates 21 Items
await itemSeeder.SeedDropRulesAsync(); // creates ItemDropRule entries
```

- **Catalog:** 21 items across 4 categories (Tracker, Clothing, Footwear, Accessory) and 5 rarities.
- **Drop rules:** `Boss → Items`, `Chest → Items`, `Dungeon → Items` with `DropChancePct`.

Notable:
- **Strava Sync Badge** (Rare Tracker) — auto-awarded on first Strava connect (not dropped via combat).

## AchievementSeeder

**Location:** `backend/src/LifeLevel.Api/Infrastructure/Persistence/AchievementSeeder.cs`

Creates 48 `Achievement` templates across 5 categories (Exploration, Combat, Social, Fitness, Gameplay) and 5 tiers (Bronze, Silver, Gold, Platinum, Diamond — or per CLAUDE.md: Common/Uncommon/Rare/Epic/Legendary).

Each achievement has:
- `ConditionType` (e.g., `BossesFought`, `StreakDaysAtOnce`, `TotalQuestsCompleted`)
- `TargetValue` and `TargetUnit`
- `XpReward` (first-unlock-only)

## TitleSeeder

**Location:** `backend/src/LifeLevel.Api/Infrastructure/Persistence/TitleSeeder.cs`

Creates `Title` templates: `Name, Emoji, Description, Criteria, Tier`. Criteria strings are parsed by `TitleService.CheckAndGrantTitlesAsync` against `{bossCount, streakDays, questCount, rankName}`.

## Registration

In `Program.cs`:

```csharp
builder.Services.AddScoped<WorldSeeder>();
builder.Services.AddScoped<ItemSeeder>();
builder.Services.AddScoped<AchievementSeeder>();
builder.Services.AddScoped<TitleSeeder>();

// On app start (inside Main or a hosted bootstrapper):
using (var scope = app.Services.CreateScope()) {
    await scope.ServiceProvider.GetRequiredService<WorldSeeder>().SeedAsync();
    await scope.ServiceProvider.GetRequiredService<ItemSeeder>().SeedCatalogAsync();
    await scope.ServiceProvider.GetRequiredService<ItemSeeder>().SeedDropRulesAsync();
    await scope.ServiceProvider.GetRequiredService<AchievementSeeder>().SeedAsync();
    await scope.ServiceProvider.GetRequiredService<TitleSeeder>().SeedAsync();
}
```

## Related
- [[AppDbContext and Persistence]]
- [[Adventure Map and World]]
- [[Items and Equipment]]
- [[Achievements and Titles]]
