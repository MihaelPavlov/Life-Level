---
tags: [lifelevel, reference]
aliases: [Git History, Development Timeline]
---
# Commit History Arc

> A narrative of how the project evolved. Snapshot: 2026-04-17. Use `git log` in the repo for current state — this note captures the *arc*, not live data.

## The story in 6 chapters

### Chapter 1 — Foundation
- `b56ec37` Initial commit
- `c09ffdf` initial setup
- `c8923bf` be & fe setup
- `4c72cfe` BE&FE login and register
- `1df71dd` phase 1

ASP.NET Core skeleton + JWT auth + Flutter app shell + register/login. Phase 0–1 done.

### Chapter 2 — Map & World
- `5e5d01c` refactoring map
- `77a7f89` word zone starting
- `29848d3` WORD MAP
- `5a04bbd` half workable map solution
- `60127dc` workable map zones
- `2b53225` fixing world and start quests

Introduction of the two-layer map (WorldZone + Map dungeon). Quest system landed at the same time. Phase 2–3 done.

### Chapter 3 — Architecture cleanup
- `57040f4` Backend refactoring
- `8ce434d` refactoring improvements

The modular monolith extraction. 11 modules carved out. `backend/ARCHITECTURE.txt` written as the source of truth.

### Chapter 4 — Fitness content
- `e3e0aee` quests
- `e663dbd` home xp bar fix + data seed more map node types

Quest templates filled out. More map node types (Dungeon, Crossroads) seeded. Home screen XP bar stabilized.

### Chapter 5 — Integrations & items
- `9ada57c` working integration with strava
- `e00278c` items and admin navigation panel on profile page
- `ded8af1` achievements, title ranks, integration strava fixes

Strava OAuth + webhook live (Sprints 1–4 of INTEGRATION_PLAN). Items system expanded (8→21). Achievements + titles + rank ladder shipped. Admin tab added to profile. 4 Strava bugs fixed (missing redirect_uri, double deep-link, nav-away, unique-index crash).

### Chapter 6 — Polish & integrations expansion
- `595e846` regroup design
- `234981d` Bosses logic
- `5928704` working health connect integration
- `2a8eab0` fixing reserve km

Bosses fully wired (damage formula, defeat flow, timers). Health Connect integrated with Android 14+ permissions + MIUI fallback. Map distance mechanics refined.

## Phase-by-phase status (as of 2026-04-17)

| Phase | Focus | Status |
|-------|-------|--------|
| Phase 0 | Foundation (JWT, entities, auth) | ✅ Done |
| Phase 1 | Character & activity core | ✅ Done |
| Phase 2 | Daily login & quest system | ✅ Done |
| Phase 3 | Adventure map & zone exploration | ✅ Done |
| Phase 4 | Boss raids | ✅ Done (single-player); guild raids ⏳ |
| Phase 5 | Items, inventory, equipment | ✅ Done |
| Phase 6 | Titles, ranks, achievements | ✅ Done |
| Phase 7 | Random events & seasonal content | 🟡 Partial (chests ✅, XP storms flagged, merchants ❌, seasonal ❌) |
| Phase 8 | Polish, social, notifications | 🟡 In progress (Strava + Health Connect ✅, guild ❌, push notifications ❌) |

## Migration status (ARCHITECTURE.txt)

All 11 originally-planned modules extracted. Plus 3 additional modules added post-plan:
- **Items** (Phase 5)
- **Achievements** (Phase 6)
- **Integrations** (Phase 8)

Total: **14 modules + 1 SharedKernel**.

## Related
- [[Roadmap Status]]
- [[Architecture Overview]]
- [[File Locations]]
