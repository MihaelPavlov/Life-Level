---
tags: [lifelevel, game-design]
aliases: [Quests, Daily Quests, Weekly Quests]
---
# Quest System

> Quests are time-boxed objectives that give structure to the day. Every activity logged auto-updates all matching active quests.

## Quest types

| Type | Count | Refresh | Expires | Bonus |
|------|-------|---------|---------|-------|
| Daily | 5 | Every 24 h (midnight UTC) | Tomorrow midnight | **+300 XP when all 5 complete** (once per day) |
| Weekly | 3 | Every Sunday (midnight UTC) | Next Sunday midnight | – |
| Special | Unlimited | Assigned lazily on first request | `2099-12-31` (effectively never) | – |

## Quest categories

`QuestCategory` enum:

- `duration` — ⏱️ XP per minute active
- `calories` — 🔥 total calories burned
- `distance` — 📍 kilometers
- `workouts` — 🏋️ number of activities
- `streak` — 🔥 consecutive days (weekly/special)
- `login` — 📅 daily login (weekly/special)

## Daily quest selection strategy

When the day rolls over, `QuestService.GenerateDailyQuestsAsync` picks 5:

1. 1 quest from `Duration` category
2. 1 quest from `Calories` or `Distance`
3. 3 from the remaining pool (random)

The same set of 5 is active all day; each has `TargetValue` + `TargetUnit`.

## Progress update flow

When an activity is logged:

1. `ActivityService.LogActivityAsync` calls `IQuestProgressPort.UpdateProgressFromActivityAsync(userId, type, duration, distance, calories)`.
2. `QuestService` loads all active `UserQuestProgress` rows (not yet expired, not yet completed).
3. For each matching quest category, increments `CurrentValue`.
4. If `CurrentValue >= TargetValue`: set `IsCompleted=true`, `CompletedAt=now`, award `quest.RewardXp` via `ICharacterXpPort`.
5. If all 5 daily quests completed today and the bonus hasn't been awarded yet: award **+300 XP** flat via `ICharacterXpPort`, mark `BonusAwarded=true`.
6. Returns `QuestProgressUpdateResult(UpdatedQuests, AllDailyCompleted, BonusXpAwarded)`.

## Completion events

When a quest completes, `QuestCompletedEvent` is published. When the 5th daily quest completes, `AllDailyQuestsCompletedEvent` also fires.

## Endpoints

- `GET /api/quests/daily` — returns active dailies (auto-generates if empty)
- `GET /api/quests/weekly` — returns active weeklies (auto-generates if empty)
- `GET /api/quests/special` — returns special quests (auto-assigns templates)
- `POST /api/quests/generate/daily` — force regenerate (debug/testing)
- `POST /api/quests/generate/weekly` — force regenerate (debug/testing)

## Related
- [[Activity System]]
- [[XP and Leveling]]
- [[Quest]] (backend module)
- [[Feature - Quests]] (mobile)
