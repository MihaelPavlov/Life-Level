---
tags: [lifelevel, game-design]
aliases: [Quests, Daily Quests, Weekly Quests]
---
# Quest System

> Tasks are time-boxed objectives inside the unified Rewards modal. Every activity logged auto-updates all matching active tasks.

## Quest types

| Type | Count | Refresh | Expires | Bonus |
|------|-------|---------|---------|-------|
| Daily | 10 | Midnight UTC | Tomorrow midnight | 10 Daily Points each |
| Weekly | 10 | Monday 00:00 UTC | Next Monday | 20 Weekly Points each |
| Special | Unlimited | Assigned lazily on first request | `2099-12-31` (effectively never) | – |

## Quest categories

`QuestCategory` enum:

- `duration` — ⏱️ XP per minute active
- `calories` — 🔥 total calories burned
- `distance` — 📍 kilometers
- `workouts` — 🏋️ number of activities
- `streak` — 🔥 consecutive days (weekly/special)
- `login` — 📅 daily login (weekly/special)

## Task selection and rewards

Each period receives a rotating set of 10 active templates, with up to three activity-specific tasks and the remainder general tasks. Reward values are snapshotted onto `UserQuestProgress` when assigned.

- Daily: nine tasks award 15 coins and one awards 1 crystal; every task awards 10 Daily Points.
- Weekly: eight tasks award 30 coins and two award 1 crystal; every task awards 20 Weekly Points.
- Task currency rewards are granted automatically when the task completes.

Milestone rewards require a tap in the Rewards modal:

| Track | Milestones |
|---|---|
| Daily | 20: 25 coins; 40: 50 XP; 60: 1 crystal; 80: 75 coins; 100: 150 XP + 1 shield |
| Weekly | 40: 100 coins; 80: 150 XP; 120: 2 crystals; 160: 200 coins; 200: 500 XP + 1 shield |

## Progress update flow

When an activity is logged:

1. `ActivityService.LogActivityAsync` calls `IQuestProgressPort.UpdateProgressFromActivityAsync(userId, type, duration, distance, calories)`.
2. `QuestService` loads all active `UserQuestProgress` rows (not yet expired, not yet completed).
3. For each matching quest category, increments `CurrentValue`.
4. If `CurrentValue >= TargetValue`: set `IsCompleted=true`, `CompletedAt=now`, and auto-grant the snapshotted coins or crystal.
5. Special quests retain direct XP rewards; daily and weekly XP comes from claimable milestones.
6. Completed task points unlock the period's milestone claims.

## Completion events

When a task completes, `QuestCompletedEvent` is published for downstream systems such as seasons and notifications.

## Endpoints

- `GET /api/quests/daily` — returns active dailies (auto-generates if empty)
- `GET /api/quests/weekly` — returns active weeklies (auto-generates if empty)
- `GET /api/quests/special` — returns special quests (auto-assigns templates)
- `POST /api/quests/generate/daily` — force regenerate (debug/testing)
- `POST /api/quests/generate/weekly` — force regenerate (debug/testing)
- `GET /api/rewards` — combined wallet, 7-day login cycle, daily track, and weekly track
- `POST /api/rewards/milestones/{daily|weekly}/{threshold}/claim` — claim one unlocked milestone once

## Related
- [[Activity System]]
- [[XP and Leveling]]
- [[Quest]] (backend module)
- [[Feature - Quests]] (mobile)
