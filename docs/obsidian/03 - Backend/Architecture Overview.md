---
tags: [lifelevel, backend]
aliases: [Backend Architecture, Modular Monolith]
---
# Architecture Overview

> Modular monolith with Ports & Adapters. Single deployable, multiple class libraries — each business domain is its own module with explicit contracts.

## Source of truth

`backend/ARCHITECTURE.txt` in the repo is the canonical architecture document. This note summarises it; for any conflict, the text file wins.

## Structure

```
backend/
├── LifeLevel.slnx
├── src/
│   ├── LifeLevel.Api/                     ← thin composition root (controllers + DI)
│   └── modules/
│       ├── LifeLevel.SharedKernel/         ← contracts, ports, events
│       ├── LifeLevel.Modules.Identity/
│       ├── LifeLevel.Modules.Character/
│       ├── LifeLevel.Modules.Activity/
│       ├── LifeLevel.Modules.Quest/
│       ├── LifeLevel.Modules.Streak/
│       ├── LifeLevel.Modules.LoginReward/
│       ├── LifeLevel.Modules.Map/
│       ├── LifeLevel.Modules.WorldZone/
│       ├── LifeLevel.Modules.Adventure.Encounters/
│       ├── LifeLevel.Modules.Adventure.Dungeons/
│       ├── LifeLevel.Modules.Items/
│       ├── LifeLevel.Modules.Achievements/
│       └── LifeLevel.Modules.Integrations/
└── tests/
    ├── LifeLevel.Api.Tests/
    ├── LifeLevel.Modules.Character.Tests/
    └── LifeLevel.Modules.Activity.Tests/
```

## Internal layout (every module follows this convention)

```
LifeLevel.Modules.{Name}/
├── Domain/
│   ├── Entities/            ← module-owned entities only
│   ├── Enums/
│   └── Events/              ← domain events this module raises
├── Application/
│   ├── Ports/
│   │   ├── In/              ← driving ports: IXxxService (called by controllers)
│   │   └── Out/             ← driven ports: IXxxRepository, cross-module read ports
│   ├── UseCases/            ← service implementations
│   └── DTOs/
├── Infrastructure/
│   ├── Persistence/
│   │   ├── Configurations/  ← IEntityTypeConfiguration<T>
│   │   └── Repositories/
│   └── {Name}Module.cs      ← AddXxxModule(IServiceCollection) extension
```

## Project dependency DAG

```
LifeLevel.Api         → all modules + SharedKernel
Identity              → SharedKernel
Character             → SharedKernel
Activity              → SharedKernel
Quest                 → SharedKernel
Streak                → SharedKernel
LoginReward           → SharedKernel
Map                   → SharedKernel
WorldZone             → SharedKernel
Adventure.Encounters  → SharedKernel, Map
Adventure.Dungeons    → SharedKernel, Map
Items                 → SharedKernel
Achievements          → SharedKernel
Integrations          → SharedKernel
```

**No cycles.** Cross-module calls go through port interfaces defined in [[SharedKernel]] — so `Character` never references `Activity`, they both just reference `SharedKernel`.

## Cross-module communication (two tiers)

### Tier 1: direct interface calls (synchronous, same transaction)

Used when the caller needs the result in the same HTTP response.

- All modules awarding XP → `ICharacterXpPort.AwardXpAsync`
- `LoginRewardService` → `IStreakShieldPort.AddShieldAsync`
- `CharacterService.GetProfile` → `IStreakReadPort`, `ILoginRewardReadPort`, `IDailyQuestReadPort`

### Tier 2: in-process domain events (fire-and-await, after save)

Used when the side effect doesn't affect the response and direct coupling would create a cycle.

- `ActivityService` publishes `ActivityLoggedEvent` → `StreakActivityHandler` + `QuestActivityHandler`
- `AuthService` publishes `UserRegisteredEvent` → `CharacterCreatedHandler` (creates Character row)

Events are dispatched by [[Cross-Module Events|InProcessEventPublisher]] (no MediatR yet).

## Why modular monolith (not microservices)

- Single deployable — simpler ops at MVP stage.
- Single database — cross-module FKs still exist, so [[AppDbContext and Persistence|one AppDbContext]].
- Clean boundaries — easy to carve out any module into its own service later if needed.

## Known MVP limitations

> [!warning] In-process event delivery is **not guaranteed**.
> `ActivityLoggedEvent` is published AFTER the DB save. If `StreakActivityHandler` or `QuestActivityHandler` throws after the commit, the event is silently lost and quest/streak progress is not updated. Acceptable at MVP. Fix (when triggered): **transactional outbox pattern** (write event to `OutboxMessages` table inside same `SaveChanges`, poll from a hosted service).

## Migration status

All 11 original modules extracted (Achievements, Items, Integrations were added later). `LifeLevel.Api` is now a thin composition root:
- 16 controllers (no business logic)
- `Program.cs` wires each `AddXxxModule()` + DbContext + JWT + CORS + Swagger
- `MapService` stays in Api (cross-module entity loading would create cycles)
- `WorldSeeder` stays in Api (composition-root seeder)
- `AppDbContext` holds DbSets + cross-module FK configurations inline

## Related
- [[SharedKernel]]
- [[Cross-Module Events]]
- [[AppDbContext and Persistence]]
- [[API Endpoints]]
- [[Auth and JWT]]
