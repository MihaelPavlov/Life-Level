---
tags: [lifelevel, game-design]
aliases: [Random Events, XP Storm, Treasure Chest, Wandering Merchant]
---
# Random Events

> Spontaneous events that break the daily routine — treasure chests hiding on the map, XP storms doubling your gains, merchants selling mystery rewards.

> [!info] Implementation status: **partial**. Chests are live (persistent map nodes). XP Storm flag exists on the login reward (Day 7). Full random-event spawner / merchant system is Phase 7 target.

## Treasure Chests ✅

Chests are permanent `MapNode` entries (type = `Chest`) seeded by `WorldSeeder`, not truly random. To collect:

1. Travel to the chest's map node.
2. Complete a workout at/near the node (the "reach + activity" gate).
3. Call `POST /api/chest/{chestId}/open`.
4. Receive `OpenChestResult(RewardXp, Items)`.

State: `UserChestState(IsOpened, OpenedAt)` — one-time open per chest per user.

## XP Storms 🟡 (partial)

Design intent:
- 2-hour window during which all activity XP is **×2**.
- Announced via push notification (FCM).
- Triggered by: cron, manual admin trigger, or Day 7 login reward flag.

Current reality:
- Login reward table flags Day 7 with `IsXpStorm = true` in the response, but the XP formula does not yet apply the ×2 multiplier.
- No standalone storm spawner job.

**Stacking rule (design):** XP Storm (×2) + active streak (×1.5) = **×3** cumulative.

## Wandering Merchants 🟡 (not yet implemented)

Design intent:
- Appear in unlocked zones for a random 5–24 h window.
- Stock mystery items (rarity weighted).
- Purchase currency: XP or a soft currency (TBD).
- Disappear when timer expires.

No entities, services, or UI exist yet. This is Phase 7 work.

## Related
- [[Adventure Map and World]]
- [[XP and Leveling]] (XP storm multiplier)
- [[Login Rewards]] (Day 7 XP storm flag)
- [[Seasonal Events]] (cousins of random events)
- [[Adventure.Encounters]] (backend — Chest entity)
