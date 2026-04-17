---
tags: [lifelevel, mobile]
aliases: [Flutter Architecture, AuthGate, MainShell]
---
# App Architecture

> A Flutter app with a stateful shell, radial FAB menu, and 15 feature folders. Riverpod for state, Dio for HTTP, secure storage for JWT.

## Entry point

```dart
void main() {
  runApp(const ProviderScope(child: LifeLevelApp()));
}

class LifeLevelApp extends StatelessWidget {
  Widget build(_) => MaterialApp(
    title: 'LifeLevel',
    theme: AppTheme.dark,
    navigatorKey: navigatorKey,   // global — used by ApiClient for 401 redirect
    home: const _AuthGate(),
  );
}
```

## _AuthGate

Decides where the user goes on app launch:

1. Reads JWT via `ApiClient.getToken()`.
2. If no token → `LoginScreen`.
3. If token present → fetch `CharacterProfile`:
   - If `isSetupComplete == false` → `WelcomeSetupScreen` (class + avatar).
   - Else → `MainShell`.
4. Shows a blue loading spinner during resolution.

## MainShell

The big central widget. `ConsumerStatefulWidget` that owns:

- **Tab state** (`_tabIndex`) — active bottom nav tab
- **Radial state** (`_radialOpen`, `_ringRotation`, open/snap animation controllers)
- **Modal overlays** (`_worldOpen`, `_titlesOpen`, etc. for non-tab screens like World Map, Titles)
- **Level-up listener** (`_levelUpSub`) — StreamSubscription to `LevelUpNotifier`
- **Item-obtained listener** — fires `ItemObtainedOverlay`
- **Inventory-full listener** — fires `InventoryFullOverlay`
- **Login reward** — shows `LoginRewardScreen` dialog on app resume if available
- **Deep link handler** (`AppLinks`) — catches `lifelevel://oauth/strava?code=...` and `lifelevel://oauth/garmin?code=...`
- **Connectivity listener** (`connectivity_plus`) — invalidates key providers on reconnect
- **App lifecycle** — triggers foreground Health Connect sync on resume

## Tab rendering

Default 4 tabs: **Home**, **Quests**, **Map**, **Profile**. Rendered via `IndexedStack` so state survives tab switches.

## Radial FAB menu

Central FAB button (⚔️) above the nav bar. Tap opens a ring of 6 orbiting items at radius 130px:
- World → opens `WorldMapScreen` modal
- Guild → placeholder (future)
- Stats → placeholder
- Battle → placeholder
- Titles → `TitlesRanksScreen`
- Boss → `BossScreen`

Long-press FAB → `CustomizeRingSheet` (drag to reorder selected items).

## Global overlays

Shown above any tab, not pushed as routes:
- `LevelUpOverlay` — full-screen, fades in/out
- `ItemObtainedOverlay` — slide-up card
- `InventoryFullOverlay` — slide-up warning
- `LoginRewardScreen` — dialog

## Key files

| File | Purpose |
|------|---------|
| `lib/main.dart` | `ProviderScope` + `MaterialApp` + `_AuthGate` |
| `lib/core/shell/main_shell.dart` | `MainShell` widget |
| `lib/core/shell/shell_models.dart` | `RingItem`, `NavTab`, defaults |
| `lib/core/shell/shell_constants.dart` | Layout constants (kNavBarH, kRadius, etc.) |
| `lib/core/api/api_client.dart` | Dio singleton + JWT interception |

## Related
- [[Core Infrastructure]]
- [[Shell and Radial FAB]]
- [[Global Event Pattern]]
- [[State Management]]
- [[Routing and Deep Links]]
