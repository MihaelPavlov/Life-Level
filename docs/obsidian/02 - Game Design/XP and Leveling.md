---
tags: [lifelevel, game-design]
aliases: [XP, Leveling, XP Curve]
---
# XP and Leveling

> XP is the universal progression currency — everything you do in the real world converts into XP. When enough XP is earned, the character levels up.

## XP Curve (formula)

```csharp
// XP required to REACH the start of a level:
XpAtLevelStart(level) = level * (level - 1) / 2 * 300
```

**Sample thresholds:**

| Level | XP required |
|-------|-------------|
| 1 | 0 |
| 2 | 300 |
| 3 | 900 |
| 4 | 1,800 |
| 5 | 3,000 |
| 10 | 13,500 |
| 20 | 57,000 |
| 50 | 367,500 |

Curve shape: soft exponential (triangular number × 300). Growth is linear-quadratic — doubles roughly every ~10 levels.

## Base XP calculation per activity

```csharp
baseXp = durationMinutes * 3.0;
baseXp *= typeMultiplier;       // see Activity System table
baseXp += distanceKm * distanceBonus;  // Running 10, Cycling 8, Hiking 6, Walking 5
baseXp += calories / 10;        // calorie bonus
baseXp *= (1.0 + gearXpBonusPct / 100.0);  // equipped item XP bonus
```

## XP Multipliers (design intent)

From CLAUDE.md product spec (some not yet all implemented):

| Multiplier | Source | Value |
|------------|--------|-------|
| Activity type | Base formula | ×0.8 – ×1.3 |
| Distance bonus | Cardio activities | flat XP/km |
| Calorie bonus | All activities | +calories / 10 |
| Gear XP bonus | Equipped items (sum) | +X % |
| XP Storm | Random event, 2 hr window | ×2 |
| Streak bonus | Active streak | ×1.5 (stacks with storm → ×3) |
| Daily quest completion | All 5 dailies done | +300 XP flat bonus |
| Login reward Day 7 | 7-day cycle climax | 300 XP + XP Storm flag |

## XP sources

Anywhere the backend calls `ICharacterXpPort.AwardXpAsync(userId, source, emoji, description, xp)`:

- **Activity logging** — primary
- **Quest completion** — `quest.RewardXp` at completion moment
- **Daily bonus** — +300 XP when all 5 dailies done
- **Login reward** — 50 / 75 / 100 / 125 / 150 / 200 / 300 per cycle day
- **Zone discovery** — `zone.TotalXp` on first arrival
- **Boss defeat** — `boss.RewardXp` once per boss per defeat
- **Chest opening** — `chest.RewardXp`
- **Dungeon floor advance** — `floor.RewardXp`
- **Crossroads path choice** — `path.RewardXp`
- **Achievement first unlock** — `achievement.XpReward`

Every award also writes an `XpHistoryEntry` (last 50 viewable in mobile XP History sheet).

## Level up side effects

When XP crosses a threshold, `CharacterService.CheckAndApplyLevelUpsAsync`:

1. Increments `Character.Level`
2. Awards stat points (via setup or rank — TBD; design says level-up grants points)
3. Publishes `CharacterLeveledUpEvent(userId, previousLevel, newLevel)`
4. Mobile app listens via `LevelUpNotifier`, shows full-screen `LevelUpOverlay`

## Related
- [[Activity System]]
- [[Character System]]
- [[Character]] (backend — `XpAtLevelStart` implementation)
- [[Items and Equipment]]
- [[Login Rewards]]
- [[Random Events]]
