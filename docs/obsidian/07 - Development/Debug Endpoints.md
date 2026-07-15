---
tags: [lifelevel, dev]
aliases: [Debug API, Admin Endpoints, Teleport]
---
# Debug Endpoints

> Developer-only HTTP endpoints for fast iteration. Available on any `[Authorize]` endpoint (admin role not required for most debug — just authentication).

## Map debug — `/api/map/debug/*`

Fastest iteration on world/map features:

| Endpoint | Purpose |
|----------|---------|
| `GET /api/map/debug/nodes` | List all map nodes with type info |
| `POST /api/map/debug/teleport/{nodeId}` | Teleport + unlock node (skip travel) |
| `POST /api/map/debug/add-distance` | Body: `{ km: 5 }` — credit km without logging activity |
| `POST /api/map/debug/adjust-level` | Body: `{ delta: +5 }` — change level instantly |
| `POST /api/map/debug/unlock-node/{nodeId}` | Unlock without teleport |
| `POST /api/map/debug/unlock-all` | Unlock every node in the world |
| `POST /api/map/debug/reset-progress` | Wipe map progress (back to start) |
| `POST /api/map/debug/set-xp` | Body: `{ xp: 50000 }` — set XP directly |

## World debug

- `POST /api/world/debug/add-distance` — credit km at the overworld layer
- `POST /api/world/zone/{zoneId}/complete` — force-complete a zone, award TotalXp

## Boss debug — `/api/boss/{bossId}/debug/*`

| Endpoint | Purpose |
|----------|---------|
| `POST /set-hp` | Body: `{ hp: 100 }` — force HpDealt |
| `POST /force-defeat` | Mark as defeated, award RewardXp |
| `POST /force-expire` | Mark as expired |
| `POST /reset` | Reset state to not-activated |

## Quest debug

- `POST /api/quests/generate/daily` — force regenerate daily quests (bypasses midnight wait)
- `POST /api/quests/generate/weekly` — force regenerate weeklies

## Achievements debug

- `POST /api/achievements/check-unlocks` — manually trigger unlock evaluation

## Mobile debug panel

The Profile → Admin tab (admin-only) wraps many of these in tappable buttons. To enable Admin tab:
- Your JWT must have `role: Admin` — set `User.Role = Admin` directly in the DB or via admin panel.

## Admin web panel

Served by the ASP.NET API at `http://localhost:5128/admin/`. Auto-logins on page load via `/api/admin/config` (returns `Admin:Email` + `Admin:Password` from appsettings) — no manual JWT pasting needed while the API is running.

| File | Contents |
|------|----------|
| `index.html` | Items catalog, drop rules, grant item to user, map editor tab |
| `map.html` | Visual map node/edge editor (drag-and-drop, pan/zoom) |
| `encounters.html` | NPC encounters, loot tables, drop configuration |
| `rank-thresholds.html` | Rank XP thresholds |
| `level-unlocks.html` | Per-level unlock configuration |
| `autologin.html` | Accepts `?t=<jwt>` and stashes token to localStorage |

Say **"open admin panel"** in Claude Code to launch it via the `/admin-panel` skill.

## Related
- [[Map]]
- [[API Endpoints]]
- [[Feature - Profile]] (Admin tab)
- [[Auth and JWT]]
