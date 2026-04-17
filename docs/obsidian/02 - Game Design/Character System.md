---
tags: [lifelevel, game-design]
aliases: [Character, Stats, Rank Ladder]
---
# Character System

> Each user has one RPG character — the central progression vehicle. Level, rank, stats, title, and class define who they are in the game.

## Purpose
Give real-world fitness effort a tangible in-game identity. Every activity logged makes the character stronger in measurable ways: numbers go up, ranks unlock, titles appear.

## Core Attributes

| Attribute | Range | Purpose |
|-----------|-------|---------|
| Level | 1 → ∞ | Unlocks zones, items, quests |
| XP | 0 → ∞ | Feeds level progression (see [[XP and Leveling]]) |
| Rank | Novice → Legendary | Prestige tier based on bosses defeated |
| Class | one of N | Stat multipliers (fighter, runner, etc.) |
| Title | one equipped | Cosmetic identity badge |
| Avatar emoji | any emoji | Visual identity |

## The 5 Core Stats

| Code | Name | Gym | Running | Cycling | Yoga | Swim | Hike | Walk | Climb |
|------|------|-----|---------|---------|------|------|------|------|-------|
| STR | Strength | +3 | – | – | – | – | – | – | +2 |
| END | Endurance | – | +2 | +2 | – | +2 | +1 | +1 | +1 |
| AGI | Agility | – | +1 | +1 | – | – | +1 | – | +1 |
| FLX | Flexibility | – | – | – | +3 | – | – | – | – |
| STA | Stamina | +1 | – | – | +1 | +2 | +2 | +1 | – |

Stat cap: **100 per stat**. Spending an available stat point increases a stat by **+5**.

## Rank Ladder

Ranks are awarded automatically based on **bosses defeated**:

| Rank | Bosses required |
|------|-----------------|
| Novice | 0 |
| Warrior | 10 |
| Champion | 25 |
| Legendary | 50 |

(Note: README also lists "Veteran" between Warrior and Champion as a design target — see [[Achievements and Titles]] for the canonical ladder.)

## Inventory slots (scale with level)

| Level range | Max slots |
|-------------|-----------|
| 1–4 | 20 |
| 5–9 | 30 |
| 10–14 | 40 |
| 15–24 | 50 |
| 25–34 | 60 |
| 35–49 | 75 |
| 50+ | 100 |

## Starter bonus
On character setup (class + avatar chosen), the character is awarded **500 XP** immediately.

## Related
- [[XP and Leveling]]
- [[Activity System]]
- [[Achievements and Titles]]
- [[Character]] (backend module)
- [[Feature - Character]] (mobile)
- [[Items and Equipment]]
