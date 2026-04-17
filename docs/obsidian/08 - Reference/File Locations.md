---
tags: [lifelevel, reference]
aliases: [Where to find, File Map]
---
# File Locations

> Quick lookup: where does X live in the repo?

Repo root: `C:\Users\MihaelPavlov\repos\Home\Life-Level\`

## Top-level

| Path | Purpose |
|------|---------|
| `backend/` | ASP.NET Core API |
| `mobile/` | Flutter app |
| `design-mockup/` | HTML mockups (42 files) |
| `docs/` | Dev docs (android-dev-testing.md, changelog HTML) |
| `README.md` | Product overview |
| `CLAUDE.md` | Project context for Claude Code |
| `INTEGRATION_PLAN.txt` | Strava + Health Connect integration plan (sprints 1–4) |

## Backend

| Path | Purpose |
|------|---------|
| `backend/LifeLevel.slnx` | Solution file |
| `backend/ARCHITECTURE.txt` | **Source of truth** for modular monolith architecture |
| `backend/src/LifeLevel.Api/` | Composition root (controllers, Program.cs, AppDbContext) |
| `backend/src/LifeLevel.Api/appsettings.json` | Config + **secrets (dev only)** |
| `backend/src/LifeLevel.Api/Infrastructure/Persistence/AppDbContext.cs` | Single DbContext, 41 DbSets |
| `backend/src/LifeLevel.Api/Infrastructure/Persistence/WorldSeeder.cs` | World + zones + nodes seed |
| `backend/src/LifeLevel.Api/Infrastructure/Jobs/DailyResetJob.cs` | Midnight cron |
| `backend/src/LifeLevel.Api/Application/Services/MapService.cs` | Cross-module map orchestration |
| `backend/src/LifeLevel.Api/Controllers/` | 16 controllers |
| `backend/src/LifeLevel.Api/wwwroot/admin/` | Web admin panel (index.html + map.html) |
| `backend/src/modules/LifeLevel.SharedKernel/` | Cross-module ports, events, contracts |
| `backend/src/modules/LifeLevel.Modules.{Name}/` | Per-module class library |

## Per-module layout (example: Character)

```
LifeLevel.Modules.Character/
├── Domain/
│   ├── Entities/                 Character.cs, CharacterClass.cs, XpHistoryEntry.cs, Title.cs
│   ├── Enums/                    Rank.cs, StatType.cs
│   └── Events/                   CharacterLeveledUpEvent.cs
├── Application/
│   ├── Ports/
│   │   ├── In/                   (IService interfaces)
│   │   └── Out/                  (IRepository interfaces)
│   ├── UseCases/                 CharacterService.cs, TitleService.cs, CharacterCreatedHandler.cs
│   └── DTOs/                     CharacterSetupRequest.cs, CharacterProfileResponse.cs, ...
├── Infrastructure/
│   ├── Persistence/
│   │   ├── Configurations/       CharacterConfiguration.cs, CharacterClassConfiguration.cs, ...
│   │   └── Repositories/         CharacterRepository.cs
│   └── CharacterModule.cs        AddCharacterModule(IServiceCollection) extension
```

## Mobile

| Path | Purpose |
|------|---------|
| `mobile/pubspec.yaml` | Dependencies |
| `mobile/lib/main.dart` | Entry point (`_AuthGate`) |
| `mobile/lib/core/api/api_client.dart` | Dio singleton + JWT interceptor |
| `mobile/lib/core/constants/app_colors.dart` | Color palette |
| `mobile/lib/core/theme/app_theme.dart` | Material 3 dark theme |
| `mobile/lib/core/services/` | Global event notifiers |
| `mobile/lib/core/shell/main_shell.dart` | Root scaffold |
| `mobile/lib/core/widgets/` | Global overlays (level-up, item-obtained, inventory-full) |
| `mobile/lib/features/{name}/` | Per-feature folder |
| `mobile/android/app/src/main/AndroidManifest.xml` | Android permissions + deep-link intent filter |
| `mobile/ios/Runner/Info.plist` | iOS HealthKit descriptions + URL scheme |

## Per-feature layout (example: quests)

```
mobile/lib/features/quests/
├── screens/
│   ├── quests_screen.dart
│   └── tabs/
│       ├── daily_quests_tab.dart
│       ├── weekly_quests_tab.dart
│       └── special_quests_tab.dart
├── models/
│   └── quest_models.dart
├── services/
│   └── quest_service.dart
├── providers/
│   └── quest_provider.dart
└── widgets/
    ├── quest_card.dart
    ├── daily_bonus_card.dart
    └── (empty/error/shimmer)
```

## Design mockups

`design-mockup/` — 42 HTML files in 8 subfolders. See [[Screen Inventory]] for the complete list.

## Related
- [[Architecture Overview]]
- [[App Architecture]]
- [[Screen Inventory]]
