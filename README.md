# Life Level

> Train in the real world. Progress in a game world.

Life Level is a mobile fitness RPG that turns your workouts into RPG progression. Log real activities, level up your character, explore an adventure map, defeat bosses, and compete with friends.

---

## Features

### Character & Stats
Create an RPG character with 5 core stats that grow from your real workouts:

| Stat | Activity |
|------|----------|
| STR (Strength) | Gym / Weightlifting |
| END (Endurance) | Running / Cycling |
| AGI (Agility) | Running / Cycling |
| FLX (Flexibility) | Yoga / Stretching |
| STA (Stamina) | All activities |

Characters gain XP, level up, unlock titles (Novice → Warrior → Champion → Legend), and equip gear that provides stat bonuses.

### Activity Tracking
Log or import workouts from Google Fit, Apple Health, or Garmin Connect.

Supported activities: Running, Gym, Cycling, Yoga, Swimming, Climbing, Hiking.

Every workout converts to XP + stat gains + movement on the adventure map.

### Adventure Map
Explore an SVG-based RPG world by moving through it with real activity distance. Discover new zones, follow branching paths, and unlock regions:
- Forest of Endurance
- Mountains of Strength
- Ocean of Balance

### Quests
- **Daily quests** — 5 tasks refreshing every 24 hours
- **Story quests** — Zone-based narrative chapters
- **Weekly & Special quests** — Longer-term goals (10 km run, summit climb, etc.)

### Boss Battles
- **Regular bosses** — 7-day raids, require traveling to a zone
- **Mini-bosses** — 3-day challenges, no travel needed
- **Guild raids** — Co-op battles where all guild members contribute damage (boss regenerates if members slack)

### Streaks & Daily Login
- Maintain a daily login streak for escalating rewards
- 7-day reward cycle with ×1.5 XP bonus on Day 7
- Streak Shields let you skip 1 day without penalty
- 30-day milestone unlocks a legendary cosmetic

### Random Events
- **Treasure Chests** — Location-based drops requiring a workout to unlock
- **XP Storms** — 2-hour ×2 XP windows announced via push notification
- **Wandering Merchants** — Timed mystery-reward challenges in discovered zones

### Achievements & Titles
48 achievements across tiers: Common → Uncommon → Rare → Epic → Legendary. Equip earned titles on your profile.

### Seasonal Events
Limited-time events with exclusive rewards, event leaderboards, ×2 XP bonuses, and cosmetics/mounts unavailable outside the season.

### Social
Friends, leaderboards, challenges, and guild co-op raids.

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

### Architecture Decision: Supabase as Infrastructure, ASP.NET Core as Brain
Supabase is used **only** for managed PostgreSQL and file storage — connected to ASP.NET Core via standard EF Core connection string. All auth (JWT), business logic, XP calculations, and game mechanics live in ASP.NET Core. This avoids mixing two auth systems while still benefiting from Supabase's managed infrastructure at no extra cost on the free tier.

---

## Design Mockups

All UI prototypes are in [`design-mockup/`](./design-mockup/) as self-contained HTML files (390×844px phone frames, dark theme).

| File | Screen |
|------|--------|
| `adventure-map.html` | Core map view |
| `adventure-map-detailed.html` | Map with zone details |
| `adventure-map-flow.html` | Map interaction flows |
| `map-interactions.html` | Forks, portals, NPCs |
| `crossroads-flow.html` | Path selection |
| `boss-fight-flow.html` | Boss raid flow |
| `mini-bosses.html` | Mini-boss challenges |
| `guild-raids.html` | Co-op guild raids |
| `quests.html` | Daily & story quests |
| `random-events.html` | Chests, XP storms, merchants |
| `seasonal-events.html` | Limited-time events |
| `daily-login.html` | Login rewards & streaks |
| `achievements.html` | Achievement gallery |
| `titles-ranks.html` | Rank ladder & titles |
| `profile-full.html` | Full character profile |
| `theme-showcase.html` | Design system & colors |
| `nav-patterns.html` | Navigation patterns |
| `radial-nav.html` | FAB radial menu |
| `implementation-roadmap.html` | Phase roadmap |

---

## Implementation Roadmap

| Phase | Focus | Status |
|-------|-------|--------|
| 0 | Foundation — Spring Boot, JWT, entity stubs | Done |
| 1 | Character & Activity Core | Next |
| 2 | Daily Login & Quest System | — |
| 3 | Adventure Map & Zone Exploration | — |
| 4 | Boss Raids | — |
| 5 | Items, Inventory & Equipment | — |
| 6 | Titles, Ranks & Achievements | — |
| 7 | Random Events & Seasonal Content | — |
| 8 | Polish, Social & Notifications | — |

See `CLAUDE.md` for detailed phase breakdowns.

---

## Business Model

**Freemium**
- Free tier: core features, basic quests
- Premium tier: advanced stats, more quests, cosmetic items, customization
