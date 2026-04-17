---
tags: [lifelevel, mobile]
aliases: [Riverpod, Providers]
---
# State Management

> Riverpod 2.x (`flutter_riverpod: ^2.6.1`). Every feature defines its own providers; the app-level `ProviderScope` wraps the `MaterialApp`.

## Provider taxonomy in this project

| Provider type | When to use | Example |
|---------------|-------------|---------|
| `AsyncNotifierProvider` | Long-lived state that needs explicit refresh/mutate | `characterProfileProvider`, `bossListProvider`, `equipmentProvider` |
| `FutureProvider` | Read-only async data, cached | `activityHistoryProvider` |
| `FutureProvider.autoDispose` | Re-fetch on widget mount/unmount | `xpHistoryProvider`, `specialQuestsProvider` |
| `NotifierProvider` | Mutable state, sync access | `integrationSyncProvider` |
| `Provider` | Singleton services | `questServiceProvider`, `itemsServiceProvider` |

## Full provider catalog

### Character
- `characterProfileProvider` — `AsyncNotifierProvider<CharacterNotifier, CharacterProfile>` — fires `LevelUpNotifier` on level delta
- `xpHistoryProvider` — `FutureProvider.autoDispose<List<XpHistoryEntry>>`

### Activity
- `activityHistoryProvider` — `FutureProvider<List<ActivityHistoryDto>>`

### Quests
- `dailyQuestsProvider` — `AsyncNotifierProvider<DailyQuestsNotifier, List<UserQuestProgress>>`
- `weeklyQuestsProvider` — `AsyncNotifierProvider<WeeklyQuestsNotifier, List<UserQuestProgress>>`
- `specialQuestsProvider` — `FutureProvider.autoDispose<List<UserQuestProgress>>`

### Home
- `mapJourneyProvider` — `FutureProvider<MapFullData>` (used by Home map section)

### Map
- map-related providers are instantiated inside feature screens (Map/WorldMap have internal state controllers)

### Boss
- `bossListProvider` — `AsyncNotifierProvider<BossListNotifier, List<BossListItem>>` — includes `refresh()` for post-battle

### Items
- `equipmentProvider` — `AsyncNotifierProvider<EquipmentNotifier, CharacterEquipmentResponse>`
- `inventoryProvider` — `AsyncNotifierProvider<InventoryNotifier, InventoryResponse>`

### Integrations
- `integrationSyncProvider` — `NotifierProvider<IntegrationSyncNotifier, IntegrationSyncState>`

### Streak
- `streakProvider` — `AsyncNotifierProvider<StreakNotifier, StreakData>`

### Titles
- `titlesProvider` — `AsyncNotifierProvider<TitlesNotifier, TitlesAndRanksResponse>` — optimistic update on equip

### Achievements
- `achievementsProvider` — `FutureProvider<List<AchievementDto>>`

### Login Reward
- `loginRewardStatusProvider` — `FutureProvider<LoginRewardStatus>`
- `loginRewardProvider` — `FutureProvider<LoginRewardClaimResult>`

## Invalidation patterns

### On app reconnect (from offline)

`MainShell` subscribes to `Connectivity().onConnectivityChanged`. On reconnect, invalidates:
- `characterProfileProvider`
- `mapJourneyProvider`
- `dailyQuestsProvider`, `weeklyQuestsProvider`
- `activityHistoryProvider`
- `streakProvider`
- `equipmentProvider`, `inventoryProvider`

### On activity logged

After `ActivityService.logActivity`, invalidate:
- `characterProfileProvider` (XP, stats)
- `dailyQuestsProvider`, `weeklyQuestsProvider` (quest progress)
- `activityHistoryProvider`
- `streakProvider`
- `mapJourneyProvider` (distance added)

### On level-up

`characterProfileProvider` is refreshed and its notifier compares new level to previous — if changed, fires `LevelUpNotifier.notify(newLevel)`.

## Related
- [[App Architecture]]
- [[Global Event Pattern]]
- [[Dependencies]]
- Each `Feature - X` note lists its specific providers
