---
tags: [lifelevel, mobile]
aliases: [Notifiers, Level Up Pattern, Broadcast Streams]
---
# Global Event Pattern

> A thin cross-feature signalling layer using `StreamController<T>.broadcast()`. Any code can fire events; `MainShell` is the single listener that renders global overlays.

## Why not Riverpod for these?

- One-shot events (level-up, item-obtained) don't fit "state".
- Riverpod provider invalidation is expensive for pure UI signals.
- Need cross-feature: level-up can be triggered from Activity Logging, Login Reward, Achievement unlock, Quest completion — all with a single listener.

## The 6 notifiers

### LevelUpNotifier
`lib/core/services/level_up_notifier.dart`

```dart
final StreamController<int> _ctrl = StreamController<int>.broadcast();
Stream<int> get stream => _ctrl.stream;
void notify(int newLevel) => _ctrl.add(newLevel);
```

Any feature that awards XP (Activity, Quest, Boss, Chest, Login Reward, Achievement) calls `LevelUpNotifier.instance.notify(newLevel)` when the server response has `leveledUp = true`. `MainShell` subscribes and shows `LevelUpOverlay`.

### ItemObtainedNotifier
Fires with an `ItemDto` — used when `LogActivityResult` includes granted items. Shows `ItemObtainedOverlay` (slide-up card, rarity-coloured).

### InventoryFullNotifier
Fires with `BlockedItemInfo(itemName, itemIcon)` — the server couldn't grant an item because inventory is full. Shows `InventoryFullOverlay` with a "Level X → more slots" hint.

### NavTabNotifier
`void switchTo(String tabId)` — programmatic tab switch from any screen (e.g., a deep link lands on Map).

### MapTabNotifier
`void notify()` — fires when user selects the Map tab. `MapScreen` listens and re-fetches cached zone data.

### WorldZoneRefreshNotifier
`void notify()` — fires when distance is added or a zone completes. `WorldMapScreen` listens and re-fetches.

## Subscribing (the MainShell pattern)

```dart
late final StreamSubscription<int> _levelUpSub;

@override void initState() {
  super.initState();
  _levelUpSub = LevelUpNotifier.instance.stream.listen((level) {
    showLevelUpScreen(context, level);
  });
}

@override void dispose() {
  _levelUpSub.cancel();
  super.dispose();
}
```

## Firing (the feature pattern)

```dart
final result = await ActivityService().logActivity(request);
if (result.leveledUp) {
  LevelUpNotifier.instance.notify(result.newLevel!);
}
for (final item in result.itemsObtained) {
  ItemObtainedNotifier.instance.notify(item);
}
for (final blocked in result.blockedItems) {
  InventoryFullNotifier.instance.notify(blocked);
}
```

## Related
- [[App Architecture]]
- [[Core Infrastructure]]
- Any feature that awards XP or items
