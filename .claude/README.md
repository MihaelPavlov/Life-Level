# Claude instructions for Life-Level

Claude should treat this repository's Codex skills as the source of working rules. The equivalent Claude agents are:

| Work | Claude agent | Read first |
| --- | --- | --- |
| ASP.NET Core API, EF Core, integrations, migrations, tests | `backend` | `.claude/agents/backend.md`, `backend/ARCHITECTURE.txt` |
| Flutter screens, Riverpod, API calls, navigation, Android UX | `flutter-ui` | `.claude/agents/flutter-ui.md`, `mobile/lib/main.dart`, `mobile/lib/core/api/api_client.dart` |
| XP, stats, quests, levels, streaks, bosses, map, items, balance | `game-engine` | `.claude/agents/game-engine.md`, relevant `docs/obsidian/02 - Game Design/` note |

Use `.claude/commands/work-next-ticket.md` for board-driven implementation, `.claude/commands/project-context.md` for a compact architecture summary, and `.claude/commands/phone-test.md` for the Android device workflow.

## Shared rules

- Read existing code and the relevant design or architecture note before editing.
- Preserve backend modular-monolith boundaries and use SharedKernel ports/events for cross-module behavior.
- Keep Flutter feature code under `mobile/lib/features/`, shared infrastructure under `mobile/lib/core/`, and use the existing Riverpod, Dio, theme, and shell patterns.
- Keep game formulas centralized, explicit, and covered by focused tests for thresholds, edge cases, stacking, and regressions.
- Use `docs/new-machine-setup.md` for installation, local configuration, Android builds, and backend deployment.
- When `graphify-out/graph.json` exists, use `graphify query`, `graphify path`, or `graphify explain` for focused codebase questions. Run `graphify update .` after code changes.
- Do not expose or commit secrets, signing keys, `appsettings.json`, Firebase service-account files, or machine-local Android properties.

## Validation

Backend changes: `cd backend; dotnet build; dotnet test`.

Mobile changes: `cd mobile; flutter analyze; flutter test`.

Android device testing: pass the API URL with `--dart-define=API_BASE_URL=...`; do not modify the API client source just to switch environments.
