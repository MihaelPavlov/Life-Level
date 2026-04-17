---
tags: [lifelevel, backend]
aliases: [AppDbContext, Persistence, EF Core, DbSets]
---
# AppDbContext and Persistence

> Single EF Core DbContext shared across all modules. Each module owns its `IEntityTypeConfiguration<T>`; AppDbContext glues them together and configures cross-module FKs inline.

## Location

`backend/src/LifeLevel.Api/Infrastructure/Persistence/AppDbContext.cs`

## Strategy

**One DbContext, one migrations project.** Cross-module foreign keys (e.g. `UserBossState → UserMapProgress → User`) require a shared context at MVP. Per-module DbContexts would fragment migrations and break FK integrity.

## OnModelCreating pattern

```csharp
modelBuilder.ApplyConfigurationsFromAssembly(typeof(IdentityModule).Assembly);
modelBuilder.ApplyConfigurationsFromAssembly(typeof(CharacterModule).Assembly);
modelBuilder.ApplyConfigurationsFromAssembly(typeof(ActivityModule).Assembly);
// ... one per module

// Then: cross-module FKs inline (cannot live in module configs because
// the target type is in a different assembly)
modelBuilder.Entity<Character>()
    .HasOne<User>().WithOne()
    .HasForeignKey<Character>(c => c.UserId);
// ... etc
```

Module repositories receive `AppDbContext` (or `IAppDbContext`) via DI.

## 41 DbSets

### Identity (2)
- `Users`
- `UserRingItems`

### Character (5)
- `Characters`
- `CharacterClasses`
- `XpHistoryEntries`
- `Titles`
- `CharacterTitles`

### Activity (1)
- `Activities`

### Quest (2)
- `Quests`
- `UserQuestProgress`

### Streak (1)
- `Streaks`

### LoginReward (1)
- `LoginRewards`

### WorldZone (5)
- `Worlds`
- `WorldZones`
- `WorldZoneEdges`
- `UserWorldProgresses`
- `UserZoneUnlocks`

### Map (4)
- `MapNodes`
- `MapEdges`
- `UserMapProgresses`
- `UserNodeUnlocks`

### Adventure.Encounters (4)
- `Bosses`
- `Chests`
- `UserBossStates`
- `UserChestStates`

### Adventure.Dungeons (6)
- `DungeonPortals`
- `DungeonFloors`
- `Crossroads`
- `CrossroadsPaths`
- `UserDungeonStates`
- `UserCrossroadsStates`

### Items (4)
- `Items`
- `CharacterItems`
- `EquipmentSlots`
- `ItemDropRules`

### Integrations (3)
- `ExternalActivityRecords`
- `StravaConnections`
- `GarminConnections`

### Achievements (2)
- `Achievements`
- `UserAchievements`

## Cross-module foreign keys (configured in OnModelCreating)

- `Character → User` (1:1)
- `Activity → Character` (N:1)
- `Streak → User` (1:1)
- `LoginReward → User` (1:1)
- `UserQuestProgress → User` (N:1)
- `UserWorldProgress → User` (N:1)
- `UserZoneUnlock → User` (N:1)
- `MapNode → WorldZone` (N:1, optional)
- `UserMapProgress → User` (N:1)
- `UserNodeUnlock → User` (N:1)
- `Boss → MapNode` (1:1)
- `Chest → MapNode` (1:1)
- `UserBossState → User + UserMapProgress` (N:1 each)
- `UserChestState → User + UserMapProgress` (N:1 each)
- `DungeonPortal → MapNode` (1:1)
- `Crossroads → MapNode` (1:1)
- `CrossroadsPath → MapNode` (optional, N:1)
- `UserDungeonState → User + UserMapProgress` (N:1 each)
- `UserCrossroadsState → User + UserMapProgress` (N:1 each)
- `CharacterItem → Character` (N:1, cascade delete)
- `EquipmentSlot → Character` (N:1, cascade delete)
- `ExternalActivityRecord → Character` (N:1, cascade delete)
- `StravaConnection → User` (N:1, cascade delete)
- `GarminConnection → User` (N:1, cascade delete)
- `UserAchievement → User` (N:1, cascade delete)

## Provider

**PostgreSQL** via `Npgsql.EntityFrameworkCore.PostgreSQL`. Connection string points to Supabase-hosted Postgres (see [[Environment Setup]]). Supabase Auth is **not** used — JWT is handled entirely server-side.

## Future path

If we outgrow a single DbContext, each module can define `{Name}DbContext` that overrides `OnModelCreating` to configure only its tables. Mechanical refactor, not architectural rethink.

## Related
- [[Architecture Overview]]
- [[Seeders]]
- Each `[[Modules/<Name>]]` note lists its DbSets
