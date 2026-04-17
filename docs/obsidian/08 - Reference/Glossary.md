---
tags: [lifelevel, reference]
aliases: [Terminology, Definitions]
---
# Glossary

> Quick lookup for potentially confusing terms. When two names could be mistaken for each other, look here first.

## Progression

| Term | Definition |
|------|------------|
| **Level** | Integer attribute on `Character`, grows from XP. Unlimited ceiling. Unlocks zones, items. |
| **XP** | Experience points. Cumulative, never decreases. See [[XP and Leveling]]. |
| **Rank** | Prestige tier (Novice → Warrior → Champion → Legendary). Auto-awarded by boss-defeat count. |
| **Title** | Equippable identity badge (e.g., "Iron-Willed", "Early Bird"). Cosmetic only. |
| **Class** | Character archetype with stat multipliers. Chosen at setup. |

## World vs Map

| Term | Layer | Entities | Purpose |
|------|-------|----------|---------|
| **WorldZone** | Overworld | `World`, `WorldZone`, `WorldZoneEdge` | Named regions (Forest of Endurance, etc.). Level-gated. |
| **Map** | Dungeon layer | `MapNode`, `MapEdge` | Encounter graph *inside* a zone: Boss, Chest, Dungeon, Crossroads. |

Users arrive at a Zone via the overworld, then explore its internal Map.

## Encounter node types

| Type | Owner module | What happens |
|------|--------------|--------------|
| **Boss** | [[Adventure.Encounters]] | 7-day timer fight, damage from activities |
| **Chest** | [[Adventure.Encounters]] | One-time open, XP + items |
| **DungeonPortal** | [[Adventure.Dungeons]] | Multi-floor dungeon, XP per floor |
| **Crossroads** | [[Adventure.Dungeons]] | Branching paths, choose one → teleport to its destination node |

## Boss variants

| Term | Travel required | Timer | Co-op |
|------|-----------------|-------|-------|
| **Regular boss** | Yes (`CurrentNodeId == Boss.NodeId`) | 7 days | No |
| **Mini-boss** | No (`IsMini = true`) | 3 days | No |
| **Guild raid** | TBD | TBD | Yes (shared HP pool) — **not yet implemented** |

## Quest types

| Type | Count | Refresh cadence | Expiry |
|------|-------|-----------------|--------|
| **Daily** | 5 | Every midnight UTC | Tomorrow midnight |
| **Weekly** | 3 | Every Sunday midnight UTC | Next Sunday midnight |
| **Special** | Unlimited | Lazy on first request | `2099-12-31` (never) |

## Events — Domain vs Broadcast Stream

| Pattern | Where | What |
|---------|-------|------|
| **Domain event** (backend) | `IDomainEvent` in [[SharedKernel]] | Backend cross-module event, fired after DB save |
| **Broadcast stream** (mobile) | `StreamController<T>.broadcast()` in `lib/core/services/` | Flutter cross-feature UI signal (level-up, item-obtained) |

Both are "events" but unrelated — one is server-side C#, the other is client-side Dart.

## Shields

`Streak.ShieldsAvailable` — one "skip-a-day" insurance token. Awarded:
- Every 7 `TotalDaysActive` (automatic)
- Login reward Day 3 (once per cycle)

Consumed:
- Implicitly by `StreakService.RecordActivityDayAsync` when gap is 2 days (not 3+)
- Explicitly via `POST /api/streak/use-shield`

## XP Storm

2-hour window with ×2 XP. Announced via push notification. Triggered by Day 7 login reward (flag set in response) or cron. **Multiplier not yet wired into XP formula** — Phase 7 target.

## Ports

Cross-module interfaces in [[SharedKernel]]. Each module owns its implementations; other modules depend on the interface only (no concrete type references).

- **Driving port** — called from outside into the module (e.g., `ICharacterXpPort` called by Activity).
- **Driven port** — the module calls outward (e.g., `IActivityLogPort` called by Integrations to log external activities).

## Related
- [[MOC|00 - Life-Level MOC]]
- [[File Locations]]
- [[Architecture Overview]]
