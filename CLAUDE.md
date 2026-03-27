# Life Level - Project Context

## Product Overview

**Working titles:** Fitness RPG / LifeLevel / RealQuest

A mobile platform that gamifies physical activity by combining:
- Fitness tracker (like Strava)
- RPG game (like World of Warcraft)
- Social network

**Core idea:** "Train in the real world → progress in a game world."

---

## Core Features

### Character System
Each user has an RPG character with:

**Core Stats (5):**
- `STR` Strength — gym/weightlifting
- `END` Endurance — running/cycling
- `AGI` Agility — running/cycling
- `FLX` Flexibility — yoga/stretching
- `STA` Stamina — all activities

**Additional attributes:** Level, XP, Rank, Titles, Class

**Activity → Stat mapping:**
- Running → END + AGI
- Gym → STR + STA
- Yoga → FLX + STA
- Cycling → END + AGI

### Activity System
Users log or import workouts. Supported integrations: Google Fit, Apple Health, Garmin Connect.

Activity types: Running, Gym, Cycling, Yoga, Swimming, Climbing, Hiking.

Each activity converts to: XP + Stat increases + Map movement. Factors: duration, calories, heart rate, distance.

**XP Multipliers:**
- Base XP × activity type modifier × duration
- Distance bonus for running/cycling
- XP Storm: ×2 multiplier
- Streak bonus: ×1.5 (stacks to ×3 during storms)
- Daily quest completion bonus: +300 XP for all 5

### Level & Progression
XP is exponential. Level-up unlocks: new zones, items, quests.

### Adventure Map
SVG-based RPG map. Player moves via real activity (distance = map movement). Regions include:
- Forest of Endurance
- Mountains of Strength
- Ocean of Balance

**Path/Crossroads System:**
- Branching paths with unlock requirements
- Some paths blocked by mini-bosses
- Path difficulty: Easy (2 days), Moderate (4 days), etc.
- Progress tracked by activity distance

### Quest System
- **Daily:** 5 quests refreshing every 24h (e.g., 30 min workout, 300 calories)
- **Weekly:** 3 workouts, 10 km running
- **Story:** Zone-based narrative chapters with multi-quest progression
- **Special:** First 10 km, summit climb, etc.

### Streak & Login Rewards
- Daily login required to maintain streak
- 7-day reward cycle (Day 7 = ×1.5 XP bonus)
- Streak Shield: skip 1 day penalty-free, earned every 7 days
- 30-day milestone unlocks legendary cosmetic
- Broken streak recovery screen with motivational messaging

### Boss & Challenge System
- **Regular Bosses:** 7-day timer, require travel to zone, single-player
- **Mini-Bosses:** 3-day timer, no travel, smaller rewards
- **Guild Raids:** Shared HP pool, all members contribute damage, boss regenerates if members slack
- Top damage dealer in guild raid gets bonus XP

### Random Events
- **Treasure Chests:** Location-based, must reach + complete workout
- **XP Storms:** 2-hour window with ×2 XP, announced via push notification
- **Wandering Merchants:** Timed 5–24h, appear in unlocked zones, mystery rewards

### Titles, Ranks & Achievements
- Rank ladder: Novice → Warrior → Veteran → Champion → Legend
- Earned titles with equip system; locked legendary titles
- 48 total achievements in tiers: Common / Uncommon / Rare / Epic / Legendary
- Category filtering, progress tracking, XP rewards, unlockable badges

### Seasonal Events
- Limited-time seasonal challenges (e.g., Winter Endurance Challenge)
- 5-stage reward ladder (XP → rare cosmetic/mount)
- Event-specific leaderboard + countdown timer
- ×2 XP bonus during event period
- Exclusive cosmetics/mounts unavailable outside season

### Social System
- Friends, Leaderboards, Challenges
- Guild system with co-op raids
- Challenges: "Most steps this week", "Most endurance gained"

### Items & Equipment
- Item types: shoes, gloves, armor, accessories, mounts
- Rarity: Common (green) → Rare (blue) → Epic (purple) → Legendary (orange)
- Effects: +XP bonus, +stat multiplier, cosmetic

---

## UI Screens
1. Character (stats, equipment, inventory, mounts)
2. Activity (log workout, XP animation)
3. Map (SVG adventure map, zone discovery)
4. Quests (daily, story, special tabs)
5. Social (friends, leaderboard, guilds)
6. Profile (ranks, titles, achievements)

---

## Design System

**Phone frame:** 390×844px (iPhone), dark theme.

**Colors:**
- Background: `#040810`, `#080e14`
- Surfaces: `#161b22`, `#1e2632`
- Text: `#e6edf3` (primary), `#8b949e` (secondary)
- Blue `#4f9eff` — actions, active states
- Purple `#a371f7` — magic, rare items
- Orange `#f5a623` — premium, rewards
- Red `#f85149` — boss, danger
- Green `#3fb950` — success, completion

**Navigation:**
- Bottom tab bar (4 items): Home, Map/Quests, Stats, Profile
- FAB boss button above nav bar, expands to radial menu

**Typography:** Inter, -apple-system, sans-serif. Headings 22–28px/700. Labels 9–10px/600 with letter-spacing.

---

## Implementation Roadmap

### Phase 0 — Foundation (DONE)
Spring Boot setup, JWT auth, SecurityConfig, entity stubs.

### Phase 1 — Character & Activity Core (3–4 weeks)
- Character entity (level, XP, rank, stats)
- Activity logging (type, duration, distance, calories)
- XP engine + stat gain system (activity type → stat mapping)
- Level-up triggers with exponential thresholds
- **UI:** Profile stats, Log Workout screen, Level-up celebration

### Phase 2 — Daily Login & Quest System (2–3 weeks)
- Quest entity (type, requirements, progress, expiry)
- Daily quest generation cron job + quest progress hooks
- Streak tracking (current, longest, shields)
- Login reward table (7-day cycle)
- **UI:** Quest tabs, streak shields, daily login screen

### Phase 3 — Adventure Map & Zone Exploration (3–4 weeks)
- Zone entity (name, difficulty, lore, parent zone)
- Movement calculation (distance → days travel)
- Zone discovery state tracking
- **UI:** SVG map, zone info panel, path selection screen

### Phase 4 — Boss Raids (3–4 weeks)
- Boss entity (name, HP, location, reward tier)
- Movement triggers raid, damage per activity, loot distribution
- Mini-boss system + Guild raid co-op mechanics
- **UI:** Boss battle display, victory screens, guild damage rankings

### Phase 5 — Items, Inventory & Equipment
- Item entity (name, type, rarity, stats, cosmetic)
- Inventory management, equipment slots
- Stat bonuses from gear

### Phase 6 — Titles, Ranks & Achievements
- Title entity + rank progression ladder
- Achievement entity (category, tier, unlock condition)
- Badge display on profile/leaderboard

### Phase 7 — Random Events & Seasonal Content
- Random event spawner (chest, XP storm, merchant)
- Seasonal event entity + limited-time quests
- Event-specific leaderboards

### Phase 8 — Polish & Advanced Features
- Push notifications (events, streaks)
- Social features (guilds, leaderboards)
- Backend optimization & caching
- Mobile app polish

---

## Tech Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| Mobile | Flutter (iOS & Android) | Single codebase, best animation quality for RPG feel |
| Backend | ASP.NET Core (C#) | REST API, business logic, game engine |
| Auth | JWT (ASP.NET Core) | Handled entirely server-side, no Supabase Auth |
| Database | Supabase (PostgreSQL) | Managed Postgres, connected via EF Core |
| Storage | Supabase Storage | Avatars, item icons, cosmetics |
| Cache / Leaderboards | Redis | Sorted sets for rankings, XP storm state |
| Real-time | SignalR | Guild raids, live events |
| Push Notifications | Firebase Cloud Messaging (FCM) | Boss spawns, XP storms, streak reminders |
| Integrations | Google Fit, Apple Health, Garmin Connect | Activity import |

**Architecture principle:** Supabase is infrastructure only (managed Postgres + storage). All auth (JWT), game logic, XP calculations, and business rules live exclusively in ASP.NET Core. Connect to Supabase Postgres via standard EF Core connection string — Supabase Auth is not used.

---

## Business Model
**Freemium**
- Free: core features, basic quests
- Premium: advanced stats, more quests, cosmetic items, customization

---

## USP
Combines real life + game progression + social competition. Makes fitness more fun, motivating, and habit-forming.

---

## Design Mockups
All UI mockups are in `design-mockup/` as HTML prototypes (390×844px phone frames):
- `adventure-map.html` / `adventure-map-detailed.html` / `adventure-map-flow.html`
- `map-interactions.html` / `crossroads-flow.html`
- `boss-fight-flow.html` / `mini-bosses.html` / `guild-raids.html`
- `quests.html` / `random-events.html` / `seasonal-events.html`
- `daily-login.html` / `achievements.html` / `titles-ranks.html`
- `profile-full.html` / `theme-showcase.html`
- `nav-patterns.html` / `radial-nav.html`
- `implementation-roadmap.html`
