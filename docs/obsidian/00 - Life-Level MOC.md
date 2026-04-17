---
tags: [lifelevel, moc]
aliases: [Life-Level Home, LifeLevel MOC]
---
# Life-Level — Map of Content

> A mobile fitness RPG: real-world activity becomes game-world progression. This is the entry point to the entire project knowledge base — click any link below to dive in.

**Working titles:** Fitness RPG / LifeLevel / RealQuest
**Core idea:** "Train in the real world → progress in a game world."
**Repo:** `C:\Users\MihaelPavlov\repos\Home\Life-Level`
**Stack:** Flutter mobile · ASP.NET Core backend · PostgreSQL (Supabase) · JWT auth · Strava + Health Connect + Garmin

---

## 01 — Product
Start here for the 10,000-foot view.

- [[Product Vision]] — USP, target user, business model
- [[Feature Catalog]] — every feature in one paragraph each
- [[Roadmap Status]] — Phase 0–8 status with evidence

## 02 — Game Design
The rules, formulas, and systems that make the game tick.

- [[Character System]] — stats, level, ranks, titles, classes
- [[Activity System]] — 8 activity types, stat-gain mapping
- [[XP and Leveling]] — the XP curve and all multipliers
- [[Quest System]] — daily / weekly / special rules
- [[Streak System]] — shields, break logic, 7-day shield cadence
- [[Login Rewards]] — 7-day cycle with XP + shield + XP storm
- [[Adventure Map and World]] — WorldZone vs Map, travel mechanics
- [[Boss System]] — regular, mini, guild raids
- [[Items and Equipment]] — rarity, slots, bonuses, drop rules
- [[Achievements and Titles]] — 48 achievements, rank ladder
- [[Random Events]] — chests, XP storms, wandering merchants
- [[Seasonal Events]] — limited-time cosmetics and leaderboards

## 03 — Backend (ASP.NET Core)
Modular monolith with 14 modules, 41 DbSets, 16 controllers.

- [[Architecture Overview]] — modular monolith + Ports & Adapters
- [[SharedKernel]] — cross-module port interfaces
- [[Cross-Module Events]] — IDomainEvent + InProcessEventPublisher
- [[AppDbContext and Persistence]] — DbSets + FK strategy
- [[API Endpoints]] — every controller + HTTP route
- [[Auth and JWT]] — BCrypt, 24h tokens, claim shape
- [[DailyResetJob]] — midnight UTC cron logic
- [[Seeders]] — WorldSeeder, ItemSeeder, AchievementSeeder, TitleSeeder

**Modules:**
- [[Identity]] — User, auth, ring items
- [[Character]] — stats, XP, level, titles
- [[Activity]] — workout logging + XP formula
- [[Quest]] — daily / weekly / special generation
- [[Streak]] — streak state + shield logic
- [[LoginReward]] — 7-day reward cycle
- [[Map]] — dungeon graph (MapNode / MapEdge)
- [[WorldZone]] — overworld graph + zone unlock
- [[Adventure.Encounters]] — Boss + Chest
- [[Adventure.Dungeons]] — DungeonPortal + Crossroads
- [[Items]] — equipment, drops, gear bonuses
- [[Achievements]] — tracking + unlock evaluation
- [[Integrations]] — Strava + Garmin + external activity dedup

## 04 — Mobile App (Flutter)
Stateful shell with radial FAB, 15 feature folders, Riverpod state.

- [[App Architecture]] — main.dart, _AuthGate, MainShell
- [[Core Infrastructure]] — ApiClient, theme, constants
- [[Global Event Pattern]] — LevelUp / ItemObtained / InventoryFull notifiers
- [[Shell and Radial FAB]] — layout constants, ring items, customization
- [[State Management]] — Riverpod provider catalog
- [[Routing and Deep Links]] — lifelevel:// scheme, Android + iOS
- [[Dependencies]] — pubspec.yaml package-by-package

**Features:**
- [[Feature - Auth]]
- [[Feature - Character]]
- [[Feature - Activity]]
- [[Feature - Quests]]
- [[Feature - Home]]
- [[Feature - Map]]
- [[Feature - Boss]]
- [[Feature - Items]]
- [[Feature - Integrations]]
- [[Feature - Profile]]
- [[Feature - Titles]]
- [[Feature - Streak]]
- [[Feature - Achievements]]
- [[Feature - Login Reward]]

## 05 — Integrations
Pulling activity data from the real world.

- [[Strava]] — Client ID 218444, OAuth + webhook
- [[Health Connect]] — Android permissions + MIUI fallback
- [[Garmin]] — OAuth 2.0 PKCE
- [[Activity Type Mapping]] — external → internal enum

## 06 — Design System
Visual language.

- [[Colors and Typography]] — AppColors constants, Inter
- [[UI Patterns]] — radial FAB, cards, overlays, sheets
- [[Screen Inventory]] — all 42 design-mockup HTML files

## 07 — Development
Day-to-day dev workflow.

- [[Environment Setup]] — backend, ngrok, Android USB
- [[Every-Session Startup]] — the 7-step checklist
- [[Strava Webhook Registration]] — re-subscribe after ngrok churn
- [[Debug Endpoints]] — teleport, add-distance, force-defeat
- [[Known Issues]] — MIUI, Garmin PKCE crypto, webhook churn

## 08 — Reference
Lookups.

- [[Glossary]] — WorldZone vs Map, Rank vs Title, etc.
- [[File Locations]] — where to find X in the repo
- [[Commit History Arc]] — narrative of recent development

---

## How to navigate this vault

1. **New to the project?** Read [[Product Vision]] → [[Feature Catalog]] → [[Roadmap Status]].
2. **Want to understand a feature?** Each game-design note links to both its backend module and its mobile feature.
3. **Debugging an activity XP bug?** [[Activity]] backend module → [[XP and Leveling]] game design → [[Feature - Activity]] mobile.
4. **Setting up a new dev session?** [[Every-Session Startup]].
5. **Lost in the code?** [[File Locations]] has a map.

All notes are tagged `#lifelevel` + one category tag for easy filtering.
