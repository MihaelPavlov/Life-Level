---
tags: [lifelevel, product]
aliases: [Roadmap, Phase Status]
---
# Roadmap Status

> Phase-by-phase status as of **2026-04-17**. Based on CLAUDE.md roadmap + ARCHITECTURE.txt migration progress + git history.

## Phase 0 — Foundation ✅

Spring Boot → ASP.NET Core setup, JWT auth, SecurityConfig, entity stubs.

**Evidence:** commits `c09ffdf`, `c8923bf`, `4c72cfe`. All scaffolding present.

## Phase 1 — Character & Activity Core ✅

- Character entity (level, XP, rank, stats) ✅
- Activity logging (type, duration, distance, calories) ✅
- XP engine + stat gain system ✅
- Level-up triggers with exponential thresholds ✅
- **UI:** Profile stats, Log Workout screen, Level-up celebration ✅

**Evidence:** commit `1df71dd` ("phase 1"). [[Character]], [[Activity]], [[XP and Leveling]].

## Phase 2 — Daily Login & Quest System ✅

- Quest entity (type, requirements, progress, expiry) ✅
- Daily quest generation cron + quest progress hooks ✅
- Streak tracking (current, longest, shields) ✅
- Login reward table (7-day cycle) ✅
- **UI:** Quest tabs, streak shields, daily login screen ✅

**Evidence:** commit `e3e0aee` ("quests"). [[Quest]], [[Streak]], [[LoginReward]], [[DailyResetJob]].

## Phase 3 — Adventure Map & Zone Exploration ✅

- Zone entity (name, difficulty, lore, parent zone) ✅
- Movement calculation (distance → days travel) ✅
- Zone discovery state tracking ✅
- **UI:** SVG / canvas map, zone info panel, path selection ✅

**Evidence:** commits `29848d3`, `60127dc`, `2b53225`. [[WorldZone]], [[Map]], [[Feature - Map]].

## Phase 4 — Boss Raids ✅ (single-player)

- Boss entity (name, HP, location, reward tier) ✅
- Movement triggers raid, damage per activity, loot distribution ✅
- Mini-boss system ✅
- **Guild raid co-op mechanics ⏳** — not started
- **UI:** Boss battle display, victory screens ✅; guild damage rankings ❌

**Evidence:** commit `234981d` ("Bosses logic"). [[Adventure.Encounters]], [[Feature - Boss]].

## Phase 5 — Items, Inventory & Equipment ✅

- Item entity (name, type, rarity, stats, cosmetic) ✅
- Inventory management, equipment slots ✅
- Stat bonuses from gear ✅
- XP bonus % from gear ✅
- Drop rules ✅

**Evidence:** commit `e00278c` ("items and admin navigation panel"). [[Items]], [[Feature - Items]].

## Phase 6 — Titles, Ranks & Achievements ✅

- Title entity + rank progression ladder ✅
- Achievement entity (category, tier, unlock condition) ✅
- Badge display on profile ✅
- 48 achievements seeded ✅

**Evidence:** commit `ded8af1` ("achivments title ranks"). [[Achievements]], [[Feature - Titles]], [[Feature - Achievements]].

## Phase 7 — Random Events & Seasonal Content 🟡 Partial

| Item | Status |
|------|--------|
| Chest encounters | ✅ (as permanent map nodes) |
| XP Storm flag on login reward Day 7 | ✅ |
| XP Storm ×2 multiplier wired into XP formula | ❌ |
| XP Storm random-spawner job | ❌ |
| Wandering Merchants | ❌ |
| Seasonal event entity | ❌ |
| Event leaderboards | ❌ |

## Phase 8 — Polish, Social & Notifications 🟡 In progress

| Item | Status |
|------|--------|
| Strava OAuth + webhook | ✅ |
| Health Connect sync | ✅ |
| Garmin OAuth | 🟡 Partial (PKCE crypto TODO) |
| Admin web panel (items + map) | ✅ |
| Network auto-refresh on reconnect | ✅ |
| Push notifications (FCM) | ❌ |
| Friends / leaderboards | ❌ |
| Guild system | ❌ |
| Mobile iOS polish (HealthKit capability in Xcode) | ❌ |
| Backend caching (Redis) | ❌ |

## Summary

- **Phase 0–6 complete.** Every core gameplay system operational.
- **Phase 7 ~25% done** (chests + XP Storm flag only).
- **Phase 8 ~40% done** (integrations + admin + connectivity; social/notifications/caching not started).

## Modular monolith status (ARCHITECTURE.txt)

All 11 originally-planned modules + 3 added later = **14 modules + SharedKernel**, all extracted. `LifeLevel.Api` is now a thin composition root (16 controllers, no business logic). Single `AppDbContext` with 41 DbSets. → [[Architecture Overview]]

## Related
- [[Product Vision]]
- [[Feature Catalog]]
- [[Commit History Arc]]
- [[Architecture Overview]]
