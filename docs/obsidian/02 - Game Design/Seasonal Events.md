---
tags: [lifelevel, game-design]
aliases: [Seasons, Limited-Time Events]
---
# Seasonal Events

> Limited-time themed challenges with exclusive cosmetics and a 5-stage reward ladder.

> [!info] Implementation status: **design only**. Mockup exists (`design-mockup/social/seasonal-events.html`) but no backend entities, services, or mobile screens yet. Phase 7 target.

## Design intent (from CLAUDE.md)

- Limited-time seasonal challenges (e.g., **Winter Endurance Challenge**).
- **5-stage reward ladder** (XP → rare cosmetic/mount).
- Event-specific leaderboard + countdown timer.
- **×2 XP bonus** active during event period.
- Exclusive cosmetics/mounts unavailable outside the season.

## Visual reference

See `design-mockup/social/seasonal-events.html` — shows:
- Event banner with theme + countdown timer
- 5-tier reward progression bar
- Leaderboard for event-scoped metrics
- ×2 XP indicator overlay

## Likely implementation shape (when built)

New module `LifeLevel.Modules.Seasons` with:
- `Season` entity (name, theme, startDate, endDate, xpMultiplier)
- `SeasonReward` entity (season, stage 1–5, rewardType, rewardRef)
- `UserSeasonProgress` (stagesClaimed, currentScore)
- Scoring metric (e.g., total distance in Winter Endurance)
- Event-specific leaderboard cache (Redis sorted set)
- Push notification trigger on event start/end

## Related
- [[Random Events]]
- [[XP and Leveling]]
- [[Achievements and Titles]]
- [[Screen Inventory]] (mockup)
