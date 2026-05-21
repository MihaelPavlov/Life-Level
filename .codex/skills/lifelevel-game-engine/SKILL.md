---
name: lifelevel-game-engine
description: Work on Life-Level game mechanics and balance. Use for XP formulas, stat gains, activity mapping, level progression, ranks, quests, streaks, login rewards, boss damage, adventure map movement, random events, items, achievements, seasons, and reward economy decisions.
---

# Life-Level Game Engine

## Core Philosophy

Real fitness effort is the fuel. Game systems should reward consistency, meaningful workouts, and exploration without becoming pay-to-win or medically prescriptive.

## Canonical Mechanics

Use the original Claude game-engine agent as historical source material:

- `.claude/agents/game-engine.md`

Use design docs for current feature detail:

- `docs/obsidian/02 - Game Design/`
- `docs/obsidian/01 - Product/Product Vision.md`
- `docs/obsidian/01 - Product/Feature Catalog.md`

## Stats

Core stats:

- `STR`: strength, mainly gym and weightlifting.
- `END`: endurance, mainly running and cycling.
- `AGI`: agility, mainly running and cycling.
- `FLX`: flexibility, mainly yoga and stretching.
- `STA`: stamina, all activity types.

Activity mapping baseline:

- Running: `END` + `AGI`
- Gym: `STR` + `STA`
- Yoga: `FLX` + `STA`
- Cycling: `END` + `AGI`
- All activities can contribute stamina or XP where existing code supports it.

## Progression

- XP should scale with effort: duration, distance, calories, and activity type where available.
- Level progression is exponential.
- Level-ups unlock zones, quests, items, ranks, and other content.
- Streaks and XP storms can multiply rewards, but avoid runaway stacking unless intentionally designed.

## Quest and Streak Rules

- Daily quests refresh every 24 hours.
- Weekly and special quests cover longer goals.
- Quest progress should be driven by real activity events.
- Streak shields should forgive limited missed days without removing the value of consistency.

## Boss and Map Rules

- Activity can convert to boss damage.
- Map travel uses real-world distance or effort-derived movement.
- WorldZone is the overworld layer.
- Map is the internal zone/dungeon graph layer.
- Keep those concepts separate in backend design.

## Items and Economy

- Use rarity tiers consistently: common, uncommon/rare where present, epic, legendary.
- Item effects can add stat bonuses, XP bonuses, or cosmetics.
- Premium should stay cosmetic or convenience-focused. Do not add pay-to-win mechanics.

## Implementation Workflow

1. Read the relevant game design doc.
2. Find the current backend service implementing the mechanic.
3. Check DTOs and mobile models if the mechanic is visible in the app.
4. Change formulas in one place when possible.
5. Add focused tests for thresholds, edge cases, stacking, and regressions.
6. Report balance assumptions explicitly.
