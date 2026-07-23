---
tags: [lifelevel, development, map, encounters]
aliases: [Trail Encounter Updates, Map Encounter System]
---
# Map Encounter Updates

Last updated: 2026-07-21

This note documents the current overworld trail encounter behavior after the recent map, blocker, merchant, story, and admin updates.

## Purpose

Trail encounters sit on `WorldZoneEdge` paths between overworld zones. They interrupt real workout distance before the player reaches the destination zone.

The intended loop is:

1. User chooses a destination zone.
2. User logs workouts or spends already banked kilometers.
3. `WorldZoneService.AddDistanceAsync` advances along the active edge.
4. If the user crosses an encounter position, movement stops at that point.
5. Excess kilometers are stored in `UserWorldProgress.PendingDistanceKm`.
6. The user explicitly resolves the encounter.
7. Pending kilometers are applied only after that explicit action.

## Encounter Types

### Story

- Displays narrative NPC content.
- Can be resolved by choosing a response or dismissing the story sheet.
- After explicit continue, pending kilometers are applied with `POST /api/world/encounter/continue`.

### Merchant

- Displays merchant inventory and XP prices.
- "Not interested" resolves the encounter and continues travel.
- Pending kilometers must not pass the merchant automatically.

### Blocker

- Spawns or reuses a linked Boss row through the trail blocker bridge.
- Sets `ActiveBlockerEncounterId`.
- Movement is capped at the blocker position until the boss is defeated.
- Defeating the boss clears the blocker and applies banked kilometers immediately.

## Placement Rules

Placement is centralized in `TrailEncounterHelper`.

Current rule: **one encounter per edge**.

Selection behavior:

- Each active `TrailEncounterTemplate` is evaluated for the edge.
- Pinned encounters have priority over random encounters.
- If several candidates qualify, the earliest `T` position on the edge wins.
- If still tied, template id is used for deterministic ordering.

Pinned placement:

- `PinnedFromZoneId` and `PinnedToZoneId` match a zone pair.
- Direction is flexible, so `A -> B` and `B -> A` both match for bidirectional use.
- `PositionFraction` fixes the encounter position from `0.0` to `1.0`.

Random placement:

- Uses deterministic seed data from `edgeId + templateId`.
- The random position is between `0.25` and `0.75` of the edge.
- Same template on the same edge always resolves the same way.

## Active Encounter State

Important distinction:

- `ActiveBlockerEncounterId` is blocker-specific and gates boss combat.
- `ActiveTrailEncounterId` is generic and prevents story/merchant encounters from being skipped.

Why `ActiveTrailEncounterId` exists:

- Story and merchant encounters used to be returned once as a DTO only.
- If the app refreshed or the user tapped destination again, the backend could treat the encounter point as already crossed.
- This allowed banked kilometers to carry the user straight to the next zone without explicit player consent.
- Persisting the active trail encounter fixes that.

While `ActiveTrailEncounterId` is set:

- Additional workout distance is banked.
- The player remains at the encounter position.
- The map read model keeps showing the encounter.
- Only `POST /api/world/encounter/continue` clears story/merchant encounters.

## Banked Kilometer Rules

Banking is expected in these cases:

- User logs distance with no destination.
- User hits a story/merchant/blocker encounter with excess distance.
- User logs more distance while an unresolved encounter is active.
- User logs more distance while blocked by an undefeated blocker boss.

Spending happens in these cases:

- User chooses a destination while `PendingDistanceKm > 0`.
- User taps Continue / Not interested for a story or merchant.
- User defeats a blocker boss and the blocker is cleared.

The backend clears `PendingDistanceKm` before replaying it through `AddDistanceAsync` to avoid double-counting.

## Backend Touchpoints

- `TrailEncounterTemplate`
  - Admin-created encounter definition.
  - Stores type, name, emoji, config JSON, spawn chance, pinned zones, and position.

- `TrailEncounterHelper`
  - Computes deterministic spawn and position.
  - Selects the single encounter for an edge.

- `WorldZoneService.AddDistanceAsync`
  - Applies workout/banked kilometers to the active edge.
  - Stops at encounters.
  - Banks excess kilometers.

- `WorldZoneService.ContinuePendingDistanceAsync`
  - Clears the active non-blocker encounter.
  - Replays pending kilometers.
  - Returns the next encounter if one is reached.

- `MapReadService.GetRegionDetailAsync`
  - Uses the same one-encounter-per-edge selection as movement.
  - Filters defeated blockers.
  - Keeps active encounters visible at their stop position.

- `WorldBossBridgeService`
  - Creates or finds the Boss row linked to a blocker template.

## Mobile Touchpoints

- `region_detail_screen.dart`
  - Handles destination selection.
  - Shows encounter intercept modal when movement returns `ActiveEncounter`.
  - Calls `continueAfterEncounter()` for story/merchant continuation.

- `encounter_intercept_sheet.dart`
  - Initial sheet shown when movement first hits an encounter.

- `encounter_merchant_sheet.dart`
  - "Not interested" now continues the journey.

- `encounter_story_sheet.dart`
  - Story choice and silent dismiss now continue the journey.

- `home_portal_card.dart`
  - Current-map section can visualize active encounters on the current edge.
  - Blockers route to boss fighting.

## Admin Panel

`/admin/encounters.html` supports:

- CRUD for trail encounter templates.
- Region-scoped encounter list.
- Pinned From Zone and To Zone dropdowns.
- Position on trail as a percentage.
- Table columns for Type, Emoji, Name, Spawn Chance, Pinned Edge, From Zone, To Zone, Position, Active, Actions.

Admin expectation:

- Use pinned From + To + Position for precise placement.
- Leave pinned zones blank for deterministic random placement.
- Only one encounter will be selected per edge, even if multiple templates qualify.

## Migration Notes

Recent schema additions:

- `Bosses.TrailEncounterTemplateId`
  - Bridges blocker trail encounters to boss fights.

- `UserWorldProgresses.ActiveTrailEncounterId`
  - Persists active story/merchant/blocker trail encounter state.
  - Required to prevent merchant/story skipping.

If local API DLLs are locked by a running backend, `dotnet ef database update` can fail during build. Stop the API before applying migrations.

## Known Edge Cases

- The fix prevents future story/merchant skips. It does not automatically rewind users who already skipped an encounter before the migration.
- If an encounter template is deleted while a user is stopped on it, the movement service clears the stale active marker and continues using normal movement rules on the next request.
- Multiple templates can still be configured for the same edge, but only one is selected at runtime.

## Related

- [[WorldZone]]
- [[Adventure Map and World]]
- [[Feature - Map]]
- [[Plan - Trail Encounters Random + Admin]]
- [[Debug Endpoints]]
