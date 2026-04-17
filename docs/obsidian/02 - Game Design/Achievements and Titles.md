---
tags: [lifelevel, game-design]
aliases: [Achievements, Titles, Rank Ladder, Badges]
---
# Achievements and Titles

> Three overlapping prestige systems: **Achievements** (48 tracked unlocks), **Titles** (equippable identity badges), and **Rank** (auto-awarded prestige tier).

## Rank ladder

Auto-advances based on **bosses defeated** (evaluated by `TitleService.CheckAndGrantTitlesAsync`):

| Rank | Bosses required |
|------|-----------------|
| Novice | 0 |
| Warrior | 10 |
| Champion | 25 |
| Legendary | 50 |

(Design spec also lists "Veteran" between Warrior and Champion in CLAUDE.md — treat as a future tier.)

Rank is stored on `Character.Rank` and displayed as a badge on the profile header and home screen.

## Achievements (48 total across 5 tiers)

```csharp
enum AchievementTier { Common, Uncommon, Rare, Epic, Legendary }
enum AchievementCategory { Exploration, Combat, Social, Fitness, Gameplay }

class Achievement {
  Guid Id;
  string Title, Description, Icon;
  AchievementCategory Category;
  AchievementTier Tier;
  int XpReward;
  string ConditionType;   // e.g., "BossesFought", "StreakDaysAtOnce", "TotalQuestsCompleted"
  int TargetValue;
  string TargetUnit;
}

class UserAchievement {
  Guid Id, UserId, AchievementId;
  int CurrentValue;
  bool IsUnlocked;
  DateTime? UnlockedAt;
}
```

## Unlock flow

`AchievementService.CheckUnlocksAsync(userId)`:

1. For each achievement, compute current value via `ComputeConditionValueAsync` (queries bosses fought, quests completed, activities, etc.).
2. Compare against `TargetValue`.
3. If newly unlocked: set `IsUnlocked = true`, `UnlockedAt = now`, award `XpReward` via `ICharacterXpPort`.
4. Return list of newly-unlocked achievement IDs.

XP is awarded **only on the first unlock** (IsUnlocked false → true transition).

## Titles (equippable)

```csharp
class Title {
  Guid Id;
  string Name, Emoji, Description, Criteria;
  int Tier;
  bool IsActive;
}

class CharacterTitle {
  Guid Id, CharacterId, TitleId;
  DateTime EquippedAt;
}
```

`TitleService.CheckAndGrantTitlesAsync(userId)` runs after boss defeats, level-ups, and other milestone events. It evaluates `Criteria` strings against `{bossCount, streakDays, questCount, rankName}` and grants matching titles.

Users can equip one title at a time via `POST /api/titles/{titleId}/equip`.

## Mobile UI

**Profile → Achievements tab** — shows all achievements with:
- Tier color-coded ribbon (Common gray → Legendary gold)
- Progress bar for in-progress
- Unlocked/locked state + XP reward
- Category filtering (Exploration, Combat, Social, Fitness, Gameplay)

**Titles Screen** (radial FAB → Titles):
- Large active title display at top
- Earned titles grid (tap to equip)
- Locked titles with unlock conditions (greyed out)
- Rank ladder widget with "bosses remaining to next rank" progress

## Endpoints

- `GET /api/achievements` — list all (optionally filter by category)
- `POST /api/achievements/check-unlocks` — force check
- `GET /api/titles` — `TitlesAndRanksResponse(activeTitleEmoji/Name, earnedTitles, lockedTitles, rankProgression)`
- `POST /api/titles/{titleId}/equip`

## Related
- [[Character System]]
- [[Boss System]]
- [[Achievements]] (backend module)
- [[Character]] (backend — TitleService)
- [[Feature - Titles]] (mobile)
- [[Feature - Achievements]] (mobile)
