# Life-Level Codex Guide

Use this file as the first project-specific context when working in this repo.

## Product

Life-Level is a fitness RPG. Real workouts produce RPG progress: XP, stat gains, map movement, quest progress, streak progress, boss damage, items, achievements, and titles.

Core principle: train in the real world, progress in a game world.

## Repository Map

- `backend/`: ASP.NET Core modular monolith API.
- `mobile/`: Flutter app for Android, iOS, and web preview.
- `docs/`: product, game design, backend, mobile, and development notes.
- `design-mockup/`: standalone HTML UI prototypes and the ticket board.
- `.claude/`: original Claude agent and command prompts used as source material.
- `.codex/`: Codex project instructions, local skills, agents, and prompt equivalents.

## Architecture

Backend source of truth:

- Read `backend/ARCHITECTURE.txt` before non-trivial backend work.
- The API is a modular monolith with ports and adapters.
- `LifeLevel.Api` is the composition root: controllers, DI, EF migrations, seeders, hosted jobs.
- Business logic belongs in modules under `backend/src/modules/`.
- Shared contracts, ports, events, and cross-module abstractions belong in `LifeLevel.SharedKernel`.
- Keep one `AppDbContext` in `LifeLevel.Api`; module EF configurations live in each module, while cross-module FK relationships stay inline in `AppDbContext`.

Backend modules:

- `LifeLevel.Modules.Identity`
- `LifeLevel.Modules.Character`
- `LifeLevel.Modules.Activity`
- `LifeLevel.Modules.Quest`
- `LifeLevel.Modules.Streak`
- `LifeLevel.Modules.LoginReward`
- `LifeLevel.Modules.WorldZone`
- `LifeLevel.Modules.Map`
- `LifeLevel.Modules.Adventure.Encounters`
- `LifeLevel.Modules.Adventure.Dungeons`
- `LifeLevel.Modules.Items`
- `LifeLevel.Modules.Achievements`
- `LifeLevel.Modules.Integrations`
- `LifeLevel.Modules.Notifications`
- `LifeLevel.SharedKernel`

## Mobile Architecture

- Entry point: `mobile/lib/main.dart`.
- Core API client: `mobile/lib/core/api/api_client.dart`.
- Theme: `mobile/lib/core/theme/app_theme.dart`.
- Main shell: `mobile/lib/core/widgets/main_shell.dart`.
- Features live under `mobile/lib/features/{feature}/`.
- Use Riverpod for state, Dio for HTTP, secure storage for JWT, and the existing feature service/provider/model split.

## Local Skills

Use these `.codex/skills` folders as local project skills:

- `lifelevel-backend`: backend API, modules, controllers, EF, tests.
- `lifelevel-flutter-ui`: Flutter screens, widgets, state, navigation, app UI.
- `lifelevel-game-engine`: XP, stats, quests, streaks, bosses, map movement, balance.

Each skill has a `SKILL.md` with trigger metadata and concise workflow guidance.

## Work Rules

- Prefer existing patterns over new abstractions.
- Do not move module boundaries without a clear reason.
- Do not inject concrete services across module boundaries; use SharedKernel ports or domain events.
- Do not add business logic to controllers.
- Do not put backend feature code directly in `LifeLevel.Api` unless it is composition-root glue, seeding, migrations, or cross-module orchestration that would otherwise create cycles.
- For UI work, match the existing dark RPG visual language and component patterns.
- For game logic, keep real-world effort as the source of progression and avoid pay-to-win mechanics.

## Validation

Backend:

```powershell
cd backend
dotnet build
dotnet test
```

Mobile:

```powershell
cd mobile
flutter analyze
flutter test
```

Use narrower tests when appropriate, but report exactly what was run and what was not.
