---
tags: [lifelevel, game-design, progression]
aliases: [Skill Tree Plan, Adaptive Skill Tree]
---
# Plan - Adaptive Skill Tree

> Build a skill tree that feels earned through real training, not only through level-up point spending.

## Core idea

Life-Level should not use a generic RPG talent tree where players dump points into abstract passives.

The stronger direction is an **adaptive skill tree**:

- **Class** gives the player a starting identity.
- **Real behavior** unlocks branches.
- **Player choice** shapes specialization.
- **Perks** feed directly into quests, streaks, map travel, and bosses.

The tree should feel like the game is discovering who the player is becoming.

## Product goals

1. Make progression feel more personal than flat stat growth.
2. Connect workouts to visible identity shifts.
3. Create medium-term goals beyond simple level-ups.
4. Increase curiosity by hiding future mastery paths until earned.
5. Reinforce the core fantasy: train in real life, evolve in-game.

## Structure

Use 4 layers instead of one large tree.

### 1. Class root

Chosen during setup.

Examples:

- Warrior
- Ranger
- Monk
- Guardian

Purpose:

- Gives fantasy and visual identity.
- Sets the first visible branch theme.
- Makes class choice matter long-term.

### 2. Behavior branches

Unlocked by repeated real-world activity.

Examples:

- Running/Cycling -> **Momentum**
- Gym/Strength -> **Power**
- Yoga/Balance -> **Focus**
- Mixed training -> **Hybrid**

Purpose:

- Reward what the user actually does.
- Make the tree adaptive rather than fully manual.

### 3. Motivation branches

Unlocked by how the player engages with the game loop.

Examples:

- **Explorer** -> map travel, fog reveal, route bonuses
- **Hunter** -> boss damage, boss prep, mini-boss bonuses
- **Discipline** -> streaks, comeback systems, daily consistency
- **Tactician** -> quest chaining, activity timing, event efficiency

Purpose:

- Tie the tree into retention systems.
- Reward engagement styles, not only workout types.

### 4. Hidden mastery branch

Revealed later from actual user patterns.

Examples:

- Trailborn
- Iron Vanguard
- Tide Sage
- Relentless One

Purpose:

- Create mystery and aspiration.
- Give players a "this is who I became" moment.

## Unlock model

Use a hybrid model:

- Some nodes unlock automatically from proof.
- Some nodes unlock after proof plus a spend decision.
- Some rare nodes unlock only through milestone achievements.

This avoids two weak extremes:

- fully automatic progression with no agency
- fully manual progression with no emotional meaning

## Best node types

Avoid mostly numeric "+3%" filler nodes.

Prefer nodes that clearly affect gameplay loops:

- **Quest node**
  Unlocks a bonus quest slot, chain quest, or reroll.

- **Travel node**
  Adds extra map movement, scouting, or hidden-route reveal.

- **Boss node**
  Buffs damage windows, prep bonuses, or post-fight rewards.

- **Streak node**
  Improves streak resilience, comeback XP, or shield quality.

- **Identity node**
  Changes title, aura, mastery badge, profile flavor, or class expression.

## Example perks

- **Momentum I**
  First activity of the day grants bonus XP.

- **Pathfinder**
  Distance-based activities give bonus world travel.

- **Boss Instinct**
  Activity logged while a tracked boss is active deals extra damage.

- **Shielded Will**
  Long streaks slightly improve streak protection value.

- **Focused Cycle**
  Repeating the same training style in a week gives a controlled bonus.

- **Hybrid Spark**
  Using 3 activity types in one week gives a reward chest.

## UX flow

The skill tree should not open as a dense spreadsheet.

Recommended flow:

1. **Insight banner**
   "You trained like a Ranger this week."
2. **Branch reveal**
   New branch glows into view with one unlocked starter node.
3. **Choice screen**
   Player picks between 2-3 unlocked nodes.
4. **Node detail**
   Clear effect, unlock condition, and linked game system.
5. **Mastery moments**
   Rare cinematic reveal when a hidden path appears.

## Screen design principles

- One strong branch focus at a time.
- Locked future paths should be teased, not fully exposed.
- The tree should look like a world map / constellation, not a corporate skill matrix.
- Class iconography should stay central.
- Every node must answer: "What behavior earns this?" and "What gameplay changes?"

## Why this is better than a normal skill tree

Normal RPG tree:

- spend points
- numbers go up
- often forgettable

Adaptive Life-Level tree:

- real effort reveals options
- identity grows from behavior
- perks feed core loops
- hidden future creates curiosity

## MVP recommendation

Start with a constrained first version:

1. 4 class roots
2. 4 universal branches
3. 12-16 meaningful nodes total
4. 1 hidden mastery reveal per player
5. UI tied into profile and post-activity reward flow

Do not start with a huge tree. The system is stronger if each node matters.

## Mockup steps

1. **Concept frame**
   Show class root + 3 fogged branches.
2. **Unlock frame**
   Show a branch revealed by real activity pattern.
3. **Choice frame**
   Show 2 unlocked nodes and 1 locked mastery path.
4. **Node detail frame**
   Explain effect and unlock requirement.
5. **Mastery reveal frame**
   Show late-game hidden branch reveal.

## Recommendation

Build the tree as a **behavior-driven progression layer**, not just another menu.

If done well, the skill tree becomes the main bridge between:

**real workouts -> RPG identity -> long-term engagement**
