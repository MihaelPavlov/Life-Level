---
tags: [lifelevel, mobile]
aliases: [ApiClient, Core Services]
---
# Core Infrastructure

> Everything in `lib/core/` — the shared plumbing that every feature folder depends on.

## Folder layout

```
lib/core/
├── api/
│   └── api_client.dart         ← Dio + JWT interceptor
├── constants/
│   └── app_colors.dart         ← color palette
├── services/
│   ├── level_up_notifier.dart
│   ├── item_obtained_notifier.dart
│   ├── inventory_full_notifier.dart
│   ├── nav_tab_notifier.dart
│   ├── map_tab_notifier.dart
│   └── world_zone_refresh_notifier.dart
├── shell/
│   ├── main_shell.dart
│   ├── shell_constants.dart
│   ├── shell_models.dart
│   └── widgets/
│       ├── boss_fab.dart
│       ├── bottom_nav_bar.dart
│       └── ring_item_tile.dart
├── theme/
│   └── app_theme.dart          ← Material 3 dark
└── widgets/
    ├── level_up_overlay.dart
    ├── item_obtained_overlay.dart
    ├── inventory_full_overlay.dart
    └── customize_ring_sheet.dart
```

## ApiClient (static singleton)

```dart
class ApiClient {
  // Default is http://10.0.2.2:5128/api on Android emulator and
  // http://127.0.0.1:5128/api on web. Override with API_BASE_URL at launch.
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    headers: { 'Content-Type': 'application/json',
               'ngrok-skip-browser-warning': 'true' },
  ));
  static final _storage = FlutterSecureStorage();

  // Request interceptor: inject Bearer token
  // Error interceptor: on 401 → clearToken + redirect to LoginScreen

  static Dio get instance => _dio;
  static Future<void> saveToken(String token) => _storage.write(key: 'jwt_token', value: token);
  static Future<void> clearToken() => _storage.delete(key: 'jwt_token');
  static Future<String?> getToken() => _storage.read(key: 'jwt_token');
  static Future<bool> isAdmin() { /* decode JWT payload, check role claim */ }
  static Future<String> get adminPanelUrl { /* web admin URL with token query param */ }
  static Future<String> get adminMapUrl { /* web map editor URL */ }
}
```

For physical-device testing the base URL is swapped to the ngrok HTTPS URL (see [[Environment Setup]]).

## Theme

`AppTheme.dark` (in `lib/core/theme/app_theme.dart`) — Material 3 dark:

- `scaffoldBackgroundColor` = `AppColors.background`
- `primary` = `AppColors.blue`
- `secondary` = `AppColors.purple`
- `fontFamily` = Inter

See [[Colors and Typography]] for the full palette.

## Core services (event notifiers)

All are `StreamController<T>.broadcast()` singletons. Decouple cross-feature signalling from Riverpod. See [[Global Event Pattern]].

## Core widgets (overlays)

Global overlays shown by `MainShell`:

- `LevelUpOverlay` — level-up celebration
- `ItemObtainedOverlay` — item drop popup, rarity-coloured
- `InventoryFullOverlay` — blocked drop warning
- `CustomizeRingSheet` — bottom sheet for radial menu reorder

## Related
- [[App Architecture]]
- [[Global Event Pattern]]
- [[Colors and Typography]]
- [[Dependencies]]
