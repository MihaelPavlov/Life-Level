---
tags: [lifelevel, backend]
aliases: [Quest Module, QuestService]
---
# Quest

> Owns daily, weekly, and special task definitions, personalized assignment, progress, claimable task currency, and task-point milestone state.

## Assignment

- Daily: 5 tasks, at most 1 adventure/guild task, reset midnight UTC.
- Weekly: 10 tasks, at most 2 adventure/guild tasks, reset Monday midnight UTC.
- Templates are grouped so near-duplicates cannot be assigned together.
- The previous 28 days select the highest target no greater than 115% of the player's median matching capacity; missing history uses the easiest variant.
- `ITaskEligibilityReadPort` removes unavailable zone, chest, boss, region, and guild objectives.
- Reward values are snapshotted once and are never recalculated for an active assignment.

## Progress modes

- `Cumulative`: add every qualifying activity or game event.
- `SingleActivity`: retain the best qualifying workout; partial workouts do not add together.

Fitness progress arrives synchronously through `IQuestProgressPort`. Adventure and guild progress uses domain events for zone completion, chest opening, boss contribution/defeat, guild contribution/victory, and region completion.

## Rewards

- Daily task: 20 points; four coin tasks at 35 coins and one crystal task.
- Weekly task: 20 points; eight coin tasks at 30 coins and two crystal tasks.
- Task currency and points activate when completed tasks are claimed. One claim collects every ready task in that period. Milestone rewards use a separate claim action.

## Public data

`UserQuestProgressDto` includes title, description, category, `progressMode`, `difficultyTier`, required activity, exact progress/target/unit, reward snapshot, completion state, and expiry.

## Related

- [[Quest System]]
- [[Activity]]
- [[Cross-Module Events]]
