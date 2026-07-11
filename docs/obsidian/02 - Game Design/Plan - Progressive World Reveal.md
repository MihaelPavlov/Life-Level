---
tags: [lifelevel, game-design, map, progression, retention]
aliases: [Hidden World Plan, Progressive Reveal Plan]
---
# Plan - Progressive World Reveal

## Goal

Increase engagement by making the world feel discoverable, earned, and slightly mysterious instead of fully visible from the start.

The core emotional loop is:

1. See where you are now.
2. See the immediate next reward.
3. Feel curiosity about what sits beyond the fog.
4. Log activity to reveal the next piece.

## Recommended Strategy

Not full hidden.

Best version for Life-Level is a **hybrid reveal system**:

- show the **current region**
- show the **current zone**
- show the **next zone**
- show a **teaser silhouette** for one future region
- hide deeper zones and later regions until unlocked

This keeps motivation high without making the world look tiny.

## Why This Is Better Than Full Visibility

### Benefits

- stronger anticipation because content is earned in steps
- clearer focus because the player is not overloaded with distant content
- cleaner onboarding because there is always one obvious next action
- better narrative pacing because each region can feel like a chapter reveal
- more satisfying unlock moments because reveal itself becomes a reward

### Risks

- if too much is hidden, the map can feel empty or cheap
- players may think the world is shallow if they do not get enough teasing
- highly exploratory users may miss seeing long-term goals

### Mitigation

- always show one `next` step
- always tease one `future region`
- use silhouettes, boss names, and short cryptic lore lines
- celebrate every reveal with a small unlock moment

## Reveal Rules

## 1. Region Visibility

At any time the player should see:

- current region: fully visible and enterable
- previously completed regions: visible and revisit-able
- next region: visible as a locked teaser card
- all later regions: hidden completely or grouped under `unknown beyond`

### Example

If the player is in `Forest of Endurance`:

- `Forest of Endurance` = active
- `Ocean of Balance` = teaser locked card
- `Mountains of Strength+` = hidden

After clearing Forest:

- `Forest of Endurance` = completed
- `Ocean of Balance` = active
- `Mountains of Strength` = teaser locked card

## 2. Zone Visibility Inside a Region

At any time the player should see:

- completed zones
- current zone
- next zone
- one fogged placeholder after the next zone
- all deeper zones hidden

### Example

Inside Forest:

- Whispering Grove = completed
- Dawn Camp = completed
- Misty Pine = current
- Ember Forge = next
- `??? Hidden Trail` = teaser
- everything after that hidden

This creates a Duolingo-like “one more step” urge.

## 3. Crossroads Visibility

Crossroads should appear only when reached.

Before reaching a crossroads:

- show one mysterious `Fork Ahead` teaser bubble

When reached:

- reveal the two branch choices
- show one as `longer safer route`
- show one as `shorter harder route`

This preserves choice tension.

## 4. Boss Visibility

Bosses should be teased early but not fully shown.

Recommended:

- region card shows boss title early
- boss art/icon stays obscured until the player is close
- boss node becomes visible only after the final pre-boss zone is revealed

This keeps the boss as a looming promise rather than just another map item.

## UX Rules

## World Screen

- center the player on one active region chapter at a time
- show completed regions above or in a compact archive style
- show the next region as a fogged cinematic card
- hide later regions from the main feed

### Teaser card content

- region silhouette
- title partially visible or fully visible
- one-line lore hook
- unlock requirement
- boss title

Example:

`Ocean of Balance`
`Locked after Forest Warden`
`Tides remember what the land forgets.`

## Region Screen

- full detail only for discovered nodes
- current node glows
- next node pulses softly
- next hidden node appears as a fog marker or rune seal

The user should always feel:

`I know what to do now, and I want to know what is behind that locked marker.`

## Motivation Layer

Each reveal should be treated as a reward, not just state change.

### Micro-rewards

- reveal animation for next zone
- short lore text unlocked
- region ambient color shift
- vibration / confetti pulse / rune burst
- codex page added

### Copy examples

- `New path revealed`
- `Fog lifted`
- `A deeper road opens`
- `The forest yields another secret`

## Narrative Advantages

This structure fits the story direction very well because each region becomes a chapter.

### Story pacing benefit

- region entry = chapter opening
- next zone reveal = page turn
- crossroads = dramatic choice
- boss reveal = chapter climax
- next region teaser = cliffhanger

That is much better for story momentum than showing the whole world map upfront.

## Backend / System Plan

## Data states needed

For regions:

- `hidden`
- `teased`
- `active`
- `completed`
- `locked-visible`

For zones:

- `hidden`
- `teased`
- `next`
- `active`
- `completed`
- `locked`

## Suggested reveal logic

### Region reveal

- first region starts as `active`
- next region starts as `teased`
- when current region boss is defeated:
  - current region becomes `completed`
  - teased region becomes `active`
  - following region becomes `teased`

### Zone reveal

- start zone visible
- next actionable zone visible
- one additional fog teaser visible
- when next zone is reached:
  - it becomes active/completed depending on state
  - the teaser becomes the next visible zone
  - one new teaser is spawned ahead

## Recommended Rollout Version

### V1

- current region visible
- next region teaser visible
- current zone visible
- next zone visible
- one fog teaser bubble visible

This is the best first shipping version.

### V2

- add reveal animations
- add codex/lore unlocks on reveal
- add boss silhouette reveal sequence

### V3

- personalized reveal messaging by class or playstyle
- dynamic teaser language based on region theme

## Success Metrics

Track whether the hidden-reveal system improves:

- map revisit rate
- session-to-session continuation
- activities logged before next unlock
- zone completion rate
- region completion rate
- day-1 to day-7 retention

Watch for failure signals:

- users not understanding where to go next
- reduced map exploration taps
- frustration around hidden content

## Final Recommendation

Yes, this is a good strategy for Life-Level if implemented as **progressive tease**, not hard blackout.

The strongest version is:

- `current`
- `next`
- `one teaser ahead`

That gives mystery, clarity, and momentum at the same time.

## Design Direction Summary

For implementation and mockups, use this rule:

- world screen = `one active chapter + one locked teaser chapter`
- region screen = `current node + next node + fogged future node`
- boss = `known by name, unknown by full form until close`

That is the most engagement-friendly version of hidden progression for this game.
