---
tags: [lifelevel, product]
aliases: [Features, Feature List]
---
# Feature Catalog

> Every feature in the product, one paragraph each, with a link to the deeper note.

## Character system
Each user has one RPG character with 5 stats (STR, END, AGI, FLX, STA), a level, a rank, an equipped title, a class, and an avatar emoji. Stats cap at 100; spending stat points adds +5 each. Rank auto-advances based on bosses defeated. → [[Character System]]

## Activity system
Users log or import workouts across 8 types (Running, Cycling, Gym, Yoga, Swimming, Hiking, Walking, Climbing). Each activity awards XP + stat gains + map travel. Channels: manual, Health Connect, Strava, Garmin. → [[Activity System]]

## XP & leveling
Quadratic curve: `level * (level-1) / 2 * 300` XP to reach level N. XP is multiplied by activity type modifier, distance bonus, calorie bonus, gear XP bonus, and (Phase 7) streak × XP Storm stacks up to ×3. → [[XP and Leveling]]

## Quest system
Three types: **Daily** (5, refresh at midnight UTC, +300 XP bonus for all-5), **Weekly** (3, refresh Sunday midnight), **Special** (unlimited, never expire). Categories: duration, calories, distance, workouts, streak, login. → [[Quest System]]

## Streak system
Consecutive activity days. Shields protect against 1 missed day per 7. Broken at midnight for 2+ day gaps without shields. Earned: +1 shield every 7 activity days + Day 3 login reward. → [[Streak System]]

## Login rewards
7-day repeating cycle: 50/75/100+shield/125/150/200/300+XP-Storm. Claim once per day. → [[Login Rewards]]

## Adventure map
Two-layer exploration: overworld zones (Forest of Endurance, Mountains of Strength, Ocean of Balance, etc.) and dungeon-layer node graphs inside each zone. Real-world km spent moves you along map edges. → [[Adventure Map and World]]

## Boss system
Regular bosses (7-day timer, travel required, single-player), mini-bosses (3-day timer, fight anywhere), guild raids (future). Damage formula: `(duration*2 + distance*10 + calories/5)`. → [[Boss System]]

## Items & equipment
5 rarity tiers (Common → Legendary), 5 equipment slots (Head/Chest/Hands/Feet/Accessory). Each item gives stat bonuses + XP percent bonus. 21 items seeded; dropped from bosses/chests/dungeons via `ItemDropRule`. → [[Items and Equipment]]

## Achievements & titles
48 achievements across 5 categories (Exploration/Combat/Social/Fitness/Gameplay) and 5 tiers. Titles equipable as cosmetic identity. Rank ladder (Novice → Warrior → Champion → Legendary) auto-awarded based on boss-defeat count. → [[Achievements and Titles]]

## Random events
Treasure Chests (live), XP Storms (flag only; ×2 multiplier not yet wired), Wandering Merchants (future). → [[Random Events]]

## Seasonal events
Design only — limited-time themed challenges with 5-stage reward ladder and exclusive cosmetics. Phase 7 target. → [[Seasonal Events]]

## Integrations
Strava (OAuth + real-time webhook), Health Connect (Android pull sync), Garmin (OAuth 2.0 + PKCE). External activities deduplicated via `ExternalId`. → [[Integrations]]

## Social (partial)
Design: friends, leaderboards, challenges, guilds with co-op raids. Implementation: **not yet started**. Phase 7/8 target.

## UI shell & radial FAB
Stateful bottom-tab shell with a centre FAB that expands into a radial menu of 6 customisable items (World, Guild, Stats, Battle, Titles, Boss by default). → [[Shell and Radial FAB]]

## Global overlays
Level-up celebration, item-obtained popup, inventory-full warning, login reward dialog — triggered by cross-feature events via broadcast streams. → [[Global Event Pattern]]

## Admin panel
Web UI for managing items, achievements, map nodes/edges. Accessed with admin-role JWT. → [[Debug Endpoints]]

## Related
- [[Product Vision]]
- [[Roadmap Status]]
- [[MOC|00 - Life-Level MOC]]
