---
tags: [lifelevel, mobile]
aliases: [Deep Links, OAuth Callback, lifelevel scheme]
---
# Routing and Deep Links

> The app doesn't use GoRouter — it's a stateful shell with an `IndexedStack` for tabs and `Navigator.push`es for secondary screens. Deep links bring the app back from external OAuth flows.

## Routing model

**No GoRouter.** All navigation is:
- `Navigator.push(MaterialPageRoute(...))` for secondary screens (Log Activity, Boss Battle, etc.)
- Tab switching via `MainShell._tabIndex` (state var)
- Modal overlays via boolean flags in `MainShell` state (`_worldOpen`, `_titlesOpen`)
- Deep links via `AppLinks`

## Route tree

```
LifeLevelApp
└── _AuthGate (home)
    ├── LoginScreen
    │   └── RegisterScreen
    ├── WelcomeSetupScreen (first-time)
    │   ├── ClassSelectionScreen
    │   ├── AvatarSelectionScreen
    │   └── CharacterCreatedScreen
    └── MainShell
        ├── [Tab] HomeScreen
        ├── [Tab] QuestsScreen → Daily/Weekly/Special tabs
        ├── [Tab] MapScreen → WorldMapScreen (toggleable)
        ├── [Tab] ProfileScreen → Overview/Equipment/Inventory/Achievements/Admin tabs
        ├── [Ring] WorldMapScreen modal
        ├── [Ring] TitlesRanksScreen
        ├── [Ring] BossScreen → BossBattleScreen
        ├── [Global Overlay] LevelUpOverlay / ItemObtainedOverlay / InventoryFullOverlay
        └── [Dialog] LoginRewardScreen (on app resume)
```

## Deep link scheme: `lifelevel://`

Used for OAuth callbacks. When Strava/Garmin redirect to `lifelevel://oauth/strava?code=...`, the OS delivers the URL to the app via `AppLinks` stream.

### Android configuration

`android/app/src/main/AndroidManifest.xml`:

```xml
<activity android:name=".MainActivity"
          android:launchMode="singleTop"
          android:taskAffinity="">
  <intent-filter android:autoVerify="false">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="lifelevel" />
  </intent-filter>
</activity>
```

`launchMode="singleTop"` + `taskAffinity=""` prevents the "double deep-link fire on cold launch" bug that was fixed in 2026-04-02 (see [[Commit History Arc]]).

### iOS configuration

`ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>lifelevel</string></array>
  </dict>
</array>
```

## MainShell handling

```dart
final _appLinks = AppLinks();
late final StreamSubscription _linkSub;

@override void initState() {
  _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
}

void _handleDeepLink(Uri uri) {
  if (uri.host == 'oauth' && uri.pathSegments.first == 'strava') {
    final code = uri.queryParameters['code'];
    if (code != null) _handleStravaCallback(code);
  }
  // ... same for garmin
}
```

## 401 redirect

When any HTTP call returns 401, `ApiClient` error interceptor:
1. Clears stored token
2. `navigatorKey.currentState?.pushAndRemoveUntil(LoginScreen, ...)`

The global `navigatorKey` is created in `main.dart` and passed to `MaterialApp.navigatorKey`.

## Related
- [[App Architecture]]
- [[Feature - Integrations]] (OAuth flows)
- [[Strava]]
- [[Garmin]]
