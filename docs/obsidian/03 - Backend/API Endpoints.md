---
tags: [lifelevel, backend]
aliases: [API, REST, Controllers, Endpoints]
---
# API Endpoints

> 16 controllers. Everything is `[Authorize]` unless noted. JSON in, JSON out. See [[Auth and JWT]] for token handling.

## AuthController — `/api/auth`
- `POST /register` — `RegisterRequest(username, email, password)` → `AuthResponse(token, refreshToken, userId)`
- `POST /login` — `LoginRequest(email, password)` → `AuthResponse`

## CharacterController — `/api/character`
- `POST /setup` — `CharacterSetupRequest(classId, avatarEmoji)` → `CharacterSetupResponse`
- `GET /me` — `CharacterProfileResponse` (includes weekly stats, streak, loginRewardAvailable, quest counts)
- `GET /xp-history` — last 50 `XpHistoryEntryResponse`
- `POST /spend-stat` — `SpendStatRequest(stat)` → 200

## ClassesController — `/api/classes`
- `GET` — list `CharacterClassResponse` (public, unauthenticated)

## ActivityController — `/api/activity`
- `POST /log` — `LogActivityRequest` → `LogActivityResult`
- `GET /history` — last 20 `ActivityHistoryDto`

## QuestController — `/api/quests`
- `GET /daily` — `List<UserQuestProgressDto>` (auto-generates)
- `GET /weekly` — `List<UserQuestProgressDto>` (auto-generates)
- `GET /special` — `List<UserQuestProgressDto>` (auto-ensures)
- `POST /generate/daily` — force regen (debug)
- `POST /generate/weekly` — force regen (debug)

## StreakController — `/api/streak`
- `GET` — `StreakDto`
- `POST /use-shield` — `UseShieldResult(success, message, shieldsRemaining)`

## LoginRewardController — `/api/login-reward`
- `GET` — `LoginRewardStatusDto`
- `POST /claim` — `LoginRewardClaimResult(xp, includesShield, isXpStorm, dayInCycle)`

## WorldZoneController — `/api/world`
- `GET /full` — `WorldFullResponse(charLevel, zones[], edges[], userProgress)`
- `PUT /destination` — `SetWorldDestinationRequest(destinationZoneId)` → 204
- `POST /debug/add-distance` — `DebugAddWorldDistanceRequest(km)` → 204
- `POST /zone/{zoneId}/complete` — `CompleteZoneResult(zoneName, xpAwarded, alreadyCompleted)`

## MapController — `/api/map`
- `GET /full?worldZoneId={id}` — `MapFullResponse(charLevel, nodes[], edges[], userProgress)`
- `PUT /destination` — `SetDestinationRequest(destinationNodeId)` → 204
- **Debug:**
  - `GET /debug/nodes`
  - `POST /debug/teleport/{nodeId}`
  - `POST /debug/add-distance`
  - `POST /debug/adjust-level`
  - `POST /debug/unlock-node/{nodeId}`
  - `POST /debug/unlock-all`
  - `POST /debug/reset-progress`
  - `POST /debug/set-xp`

## BossController — `/api/boss`
- `GET` — `List<BossListItemDto>`
- `POST /{bossId}/activate` — activate fight
- `POST /{bossId}/damage` — `DealDamageRequest(damage)` → damage result
- `POST /{bossId}/damage/activity` — `ActivityDamageRequest(type, duration, distance, calories)`
- `GET /{bossId}/state`
- **Debug:** `set-hp`, `force-defeat`, `force-expire`, `reset`

## ChestController — `/api/chest`
- `GET` — `List<ChestListItemDto>`
- `POST /{chestId}/open` — `OpenChestResult(xpAwarded, items[])`
- `GET /{chestId}/state`

## DungeonController — `/api/dungeon`
- `GET` — `List<DungeonListItemDto>`
- `POST /{dungeonId}/enter` — enter at floor 1
- `POST /{dungeonId}/advance-floor` — next floor + XP
- `GET /{dungeonId}/state`
- `POST /{dungeonId}/complete` — defeat + final XP

## CrossroadsController — `/api/crossroads`
- `GET` — `List<CrossroadsListItemDto>`
- `POST /{crossroadsId}/choose-path/{pathId}` — teleport + XP

## ItemsController — `/api/items`
- `GET /equipment` — `CharacterEquipmentResponse(slots[], totalBonuses)`
- `POST /equipment/equip` — `EquipItemRequest(characterItemId, slotType)`
- `DELETE /equipment/{slotType}` — unequip
- `GET /inventory` — unequipped items

## AchievementsController — `/api/achievements`
- `GET?category=X` — `List<AchievementDto>`
- `POST /check-unlocks` — force re-check

## TitlesController — `/api/titles`
- `GET` — `TitlesAndRanksResponse`
- `POST /{titleId}/equip`

## UserController — `/api/users`
- `GET /me` — `UserProfileDto(username, email, role, createdAt)`

## IntegrationsController — `/api/integrations`
- `POST /strava/authorize` — begin OAuth
- `POST /strava/callback` — `StravaCallbackRequest(code)`
- `GET /strava/status`
- `DELETE /strava/disconnect`
- `POST /strava/webhook` — Strava push (GET also for subscription verification)
- `POST /garmin/authorize`
- `POST /garmin/callback`
- `GET /garmin/status`
- `DELETE /garmin/disconnect`
- `POST /garmin/webhook`
- `POST /sync-batch` — batch upload activities from Health Connect

## Admin controllers (`[Authorize(Roles = "Admin")]`)

### AdminClassesController — `/api/admin/classes`
- Full CRUD for `CharacterClass`.

### AdminMapController — `/api/admin/map`
- Full CRUD for MapNodes, MapEdges, Bosses, Chests, DungeonPortals, Crossroads.

### AdminItemsController — `/api/admin/items`
- Full CRUD for Items, ItemDropRules.

## Swagger

`GET /swagger` — lists all 16 controllers with Bearer auth support.

## Related
- [[Auth and JWT]]
- [[Architecture Overview]]
- Each module's note lists its owning endpoints
