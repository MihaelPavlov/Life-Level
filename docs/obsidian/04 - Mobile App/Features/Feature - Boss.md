---
tags: [lifelevel, mobile]
aliases: [Boss Feature, Boss Screen, Boss Battle]
---
# Feature — Boss

> Boss list + boss battle screens. Activate a fight, deal damage by logging activities, celebrate defeat.

## Files

```
lib/features/boss/
├── screens/
│   ├── boss_screen.dart
│   └── boss_battle_screen.dart
├── models/
│   └── boss_list_item.dart
├── services/
│   └── boss_page_service.dart
├── providers/
│   └── boss_provider.dart
└── widgets/
    ├── boss_active_card.dart
    ├── boss_hp_bar.dart
    ├── boss_defeated_card.dart
    ├── boss_expired_card.dart
    └── boss_locked_card.dart
```

## BossScreen

Opened from the radial FAB's Boss item.

- Lists all available bosses:
  - **Active** (red, tappable) — currently being fought
  - **Defeated** (gray)
  - **Locked** (dim, level-gated)
  - **Expired** (crossed out, timer ran out)
- Per boss: name, icon, max HP, timer (days remaining), reward XP, mini/regular indicator, region + node name

Tap an active boss → `BossBattleScreen`.

## BossBattleScreen

Full-screen battle UI:
- Boss icon + name + region
- Current HP bar (gradient red, shows `hpRemaining / maxHp`)
- Timer countdown
- Player damage dealt counter
- "Deal damage" actions (open activity log flow)

On defeat or expiry → return to boss list with celebration overlay + XP reward.

## BossListItem model

```dart
class BossListItem {
  String id, name, icon;
  int maxHp, hpDealt, rewardXp, timerDays, levelRequirement;
  bool isMini, canFight, activated, isDefeated, isExpired;
  String region, nodeName;
  DateTime? startedAt, timerExpiresAt, defeatedAt;

  bool get isActive => activated && !isDefeated && !isExpired;
  int get hpRemaining => maxHp - hpDealt;
  double get hpPercent => hpDealt / maxHp;
  Duration? get timeRemaining;
}
```

## BossPageService

```dart
Future<List<BossListItem>> getAllBosses();  // GET /api/boss
```

Deal-damage methods live in the action screens (`POST /api/boss/{id}/damage` or `/damage/activity`).

## BossNotifier

```dart
final bossListProvider = AsyncNotifierProvider<BossListNotifier, List<BossListItem>>(...);

class BossListNotifier extends AsyncNotifier<List<BossListItem>> {
  Future<void> refresh();  // called after activate, damage, defeat
}
```

## Widgets

| Widget | Purpose |
|--------|---------|
| `BossActiveCard` | Red card for fighting bosses |
| `BossHpBar` | Gradient HP bar with damage label |
| `BossDefeatedCard` | Grayed-out defeated boss |
| `BossExpiredCard` | Expired boss (time up) |
| `BossLockedCard` | Level-gated boss preview |

## Related
- [[Boss System]]
- [[Adventure.Encounters]] (backend)
- [[Map]] (travel to boss node)
- [[Achievements and Titles]] (rank ladder advances on defeats)
