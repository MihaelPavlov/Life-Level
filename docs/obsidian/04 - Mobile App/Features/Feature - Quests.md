---
tags: [lifelevel, mobile]
aliases: [Quests Feature, Daily Quests, Weekly Quests]
---
# Feature — Quests

> Daily and Weekly tasks are presented in the unified Rewards sheet; Special quests remain available through the quest feature.

## Rewards presentation

- Daily/Weekly toggle with an unclaimed-milestone badge.
- Five daily or ten weekly tasks in an independently scrolling list.
- Every compact row shows the objective description, exact progress, currency reward, and task points.
- A completed unclaimed row shows `Claim`; tapping it collects every ready task in the selected period and immediately refreshes the wallet and top points track.
- Completed rows show `Completed · reward received`.
- The milestone track explains that tapping any unlocked reward claims all available milestones.
- Wallet coins/crystals and the period reset countdown stay visible above the task list.

## Model fields

`UserQuestProgress` parses the backend category, `progressMode`, `difficultyTier`, optional required activity, current/target/unit, snapshotted rewards, completion state, and expiry.

Game categories cover zones, chests, boss participation/defeat, guild raid participation/victory, and conditional region completion in addition to fitness measurements.

## Related

- [[Quest System]]
- [[Quest]] (backend)
- [[Activity System]]
- [[State Management]]
