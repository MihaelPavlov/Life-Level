---
name: lifelevel-flutter-ui
description: Work on the Life-Level Flutter mobile app. Use for screens, widgets, theme, navigation, Riverpod state, Dio API calls, secure JWT storage, Health/Strava/Garmin UI flows, app shell behavior, animations, and mobile UX in this repository.
---

# Life-Level Flutter UI

## First Reads

For non-trivial mobile work, read:

- `mobile/lib/main.dart`
- `mobile/lib/core/api/api_client.dart`
- `mobile/lib/core/theme/app_theme.dart`
- `mobile/lib/core/widgets/main_shell.dart`
- The relevant feature folder under `mobile/lib/features/`
- The relevant docs note under `docs/obsidian/04 - Mobile App/`

## App Shape

- Entry point: `main.dart`.
- Auth gate decides login vs main shell based on JWT presence.
- Main shell owns bottom tabs, radial FAB, overlays, lifecycle hooks, deep links, and global app behavior.
- Feature code lives under `mobile/lib/features/<feature>/`.
- Shared infrastructure lives under `mobile/lib/core/`.

## State and API

- Use Riverpod providers following existing feature patterns.
- Use Dio through `ApiClient.instance`.
- Store JWT via `ApiClient.saveToken`, `getToken`, and `clearToken`.
- Keep model parsing and service calls inside feature `models/`, `services/`, and `providers/` where those folders exist.
- Handle 401 by relying on `ApiClient` redirect behavior.

## UI Rules

- Match the existing dark RPG visual language.
- Use `AppTheme.dark` and existing palette/constants before adding new colors.
- Keep screens dense enough for an app, not a marketing page.
- Prefer reusable widgets inside the feature folder when repeated locally.
- Keep global widgets under `core/widgets` only when used across features.
- Do not add visible instructional copy that explains the UI mechanics unless the product flow requires it.
- Preserve mobile layout constraints; text should not overflow buttons, chips, cards, or bottom sheets.

## Navigation

- Use the existing main shell tab and overlay patterns.
- Add new deep-link behavior only where it belongs in the app shell or integration service.
- Avoid creating an unrelated routing style if a feature already uses direct widgets, overlays, or sheets.

## Tests and Checks

Run:

```powershell
cd mobile
flutter analyze
flutter test
```

For focused UI work, add or run targeted widget tests under `mobile/test/` when the behavior is user-facing or regression-prone.
