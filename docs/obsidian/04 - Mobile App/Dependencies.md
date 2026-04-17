---
tags: [lifelevel, mobile]
aliases: [pubspec, Flutter Packages]
---
# Dependencies

> `pubspec.yaml` — every package and why it's here.

## HTTP & API
| Package | Version | Purpose |
|---------|---------|---------|
| `dio` | ^5.7.0 | HTTP client with interceptors (JWT injection, 401 redirect) |
| `retrofit` | ^4.4.1 | Typed API client generation (not yet heavily used) |

## State Management
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.6.1 | Reactive state — providers for character, quests, bosses, items, etc. |
| `riverpod_annotation` | ^2.6.1 | Annotations for code-gen |

## Navigation
| Package | Version | Purpose |
|---------|---------|---------|
| `go_router` | ^14.6.2 | Pulled in but **not used** — we use a stateful shell instead. Safe to remove. |

## Storage
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_secure_storage` | ^9.2.2 | JWT token — Android EncryptedSharedPreferences, iOS Keychain |
| `shared_preferences` | ^2.3.0 | Health Connect last-sync timestamp, permission flags |

## UI helpers
| Package | Version | Purpose |
|---------|---------|---------|
| `cached_network_image` | ^3.4.1 | Image caching + progressive load |
| `flutter_svg` | ^2.0.10+1 | SVG rendering (future map layers) |
| `lottie` | ^3.1.3 | Lottie animations (level-up, celebrations) |

## Fitness integrations
| Package | Version | Purpose |
|---------|---------|---------|
| `health` | ^11.0.0 | Health Connect (Android) + HealthKit (iOS) bindings |
| `flutter_web_auth_2` | ^4.0.0 | OAuth 2 web flow (currently unused — we use `url_launcher` + deep links) |

## Deep links
| Package | Version | Purpose |
|---------|---------|---------|
| `app_links` | ^6.3.2 | `lifelevel://` deep link stream for Strava/Garmin OAuth callbacks |

## Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `intl` | ^0.19.0 | Date/time formatting |
| `equatable` | ^2.0.7 | Value equality mixin on model classes |
| `url_launcher` | ^6.3.0 | Launch OAuth URLs, Health Connect app, browser |
| `connectivity_plus` | ^6.0.0 | Online/offline detection → provider invalidation on reconnect |

## Dev dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_lints` | ^4.0.0 | Linting rules |
| `build_runner` | ^2.4.13 | Code-gen runner |
| `riverpod_generator` | ^2.6.2 | `@riverpod` codegen |
| `retrofit_generator` | ^9.1.5 | Retrofit API client codegen |
| `json_serializable` | ^6.8.0 | `fromJson/toJson` codegen |

## TODO

- `crypto` package needed for proper SHA-256 code challenge in [[Garmin]] PKCE flow — currently falls back to plain text.
- `go_router` can be removed once confirmed nothing imports it.

## Related
- [[App Architecture]]
- [[Routing and Deep Links]]
- [[Core Infrastructure]]
