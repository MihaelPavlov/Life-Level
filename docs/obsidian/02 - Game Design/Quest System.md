---
tags: [lifelevel, game-design]
aliases: [Quests, Daily Quests, Weekly Quests]
---
# Quest System

> Tasks are time-boxed objectives inside the unified Rewards modal. Every activity logged auto-updates all matching active tasks.

## Quest types

| Type | Count | Refresh | Expires | Bonus |
|------|-------|---------|---------|-------|
| Daily | 5 | Midnight UTC | Tomorrow midnight | 20 Daily Points each |
| Weekly | 10 | Monday 00:00 UTC | Next Monday | 20 Weekly Points each |
| Special | Unlimited | Assigned lazily on first request | `2099-12-31` (effectively never) | – |

## Quest categories

`QuestCategory` enum:

- `duration` — ⏱️ XP per minute active
- `calories` — 🔥 total calories burned
- `distance` — 📍 kilometers
- `workouts` — 🏋️ number of activities
- `zonesCompleted`, `chestsOpened` — eligible adventure progress
- `bossContributions`, `bossesDefeated` — active boss workouts and victories
- `guildRaidContributions`, `guildRaidsWon` — contributor-only guild progress
- `regionsCompleted` — conditional weekly region-boss victory

## Task selection and rewards

Each period receives an eligibility-filtered set: 5 daily tasks with at most one game task, and 10 weekly tasks with at most two game tasks. Near-duplicate task groups cannot appear together. Fitness variants are selected from the player's previous 28 days; unavailable chest, boss, region, and guild objectives are not assigned. Reward values are snapshotted onto `UserQuestProgress` when assigned.

- Daily: four tasks award 35 coins and one awards 1 crystal; every task awards 20 Daily Points.
- Weekly: eight tasks award 30 coins and two award 1 crystal; every task awards 20 Weekly Points.
- Completed tasks become claimable. Tapping any task Claim button collects every completed, unclaimed task in that Daily or Weekly period.

Milestone rewards require a tap in the Rewards modal:

| Track | Milestones |
|---|---|
| Daily | 20: 25 coins; 40: 50 XP; 60: 1 crystal; 80: 75 coins; 100: 150 XP + 1 shield |
| Weekly | 40: 100 coins; 80: 150 XP; 120: 2 crystals; 160: 200 coins; 200: 500 XP + 1 shield |

## Progress update flow

When an activity is logged:

1. `ActivityService.LogActivityAsync` calls `IQuestProgressPort.UpdateProgressFromActivityAsync(userId, type, duration, distance, calories)`.
2. `QuestService` loads all active `UserQuestProgress` rows (not yet expired, not yet completed).
3. Cumulative tasks add progress; `SingleActivity` tasks retain the best qualifying workout.
4. If `CurrentValue >= TargetValue`: set `IsCompleted=true` and `CompletedAt=now`; the snapshotted reward remains unclaimed.
5. `POST /api/rewards/tasks/{daily|weekly}/claim-available` claims every ready task, grants their combined currency, and activates their task points.
6. Special quests retain direct XP rewards; daily and weekly XP comes from claimable milestones.
7. Claimed task points unlock the period's milestone claims.

Adventure and guild events advance the matching categories. Guild victories count only for contributors, and region completion only fires after defeating the current region boss.

## Completion events

When a task completes, `QuestCompletedEvent` is published for downstream systems such as seasons and notifications.

## Endpoints

- `GET /api/quests/daily` — returns active dailies (auto-generates if empty)
- `GET /api/quests/weekly` — returns active weeklies (auto-generates if empty)
- `GET /api/quests/special` — returns special quests (auto-assigns templates)
- `POST /api/quests/generate/daily` — force regenerate (debug/testing)
- `POST /api/quests/generate/weekly` — force regenerate (debug/testing)
- `GET /api/rewards` — combined wallet, daily track, and weekly track
- `POST /api/rewards/tasks/{daily|weekly}/claim-available` — collect every completed unclaimed task in the period
- `POST /api/rewards/milestones/{daily|weekly}/claim-available` — claim every unlocked milestone

## Related
- [[Activity System]]
- [[XP and Leveling]]
- [[Quest]] (backend module)
- [[Feature - Quests]] (mobile)
