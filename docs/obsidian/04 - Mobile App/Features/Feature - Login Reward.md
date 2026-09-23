---
tags: [lifelevel, mobile]
aliases: [Login Reward Feature]
---
# Feature — Login Reward

> Unified Rewards modal containing Daily and Weekly task tracks. Login rewards remain backend data but are not rendered in this task modal.

## Files

```
lib/features/login_reward/
├── login_reward_screen.dart
├── models/
│   └── login_reward_models.dart
│   └── reward_center_models.dart
├── services/
│   └── login_reward_service.dart
└── providers/
    └── login_reward_provider.dart
```

## login_reward_models.dart

```dart
class LoginRewardStatus {
  int dayInCycle;             // 1–7 (next claim day)
  bool claimedToday;
  int nextRewardXp;
  bool nextRewardIncludesShield;
  bool nextRewardIsXpStorm;
  int totalLoginDays;
}

class LoginRewardClaimResult {
  int dayInCycle, xpAwarded;
  bool includesShield, isXpStorm, leveledUp;
  int? newLevel;
}
```

## LoginRewardService

```dart
Future<LoginRewardStatus> getStatus();
Future<LoginRewardClaimResult> claimReward();
Future<RewardCenterData> getRewardCenter();
Future<TaskRewardPeriod> claimMilestone(String period, int threshold);
```

## Providers

```dart
final loginRewardStatusProvider = FutureProvider<LoginRewardStatus>(...);
final loginRewardProvider = FutureProvider<LoginRewardClaimResult>(...);  // fired on claim
```

## LoginRewardScreen

Dialog showing:
- Wallet balances and reset countdown
- Daily/Weekly tabs with their own points, five milestone rewards, and ten compact task rows
- Two left-aligned reward tiles per task, automatic task reward status, and tap-to-claim milestone states

On claim:
1. Call `LoginRewardService().claim()`
2. If `leveledUp`: `LevelUpNotifier.instance.notify(newLevel)`
3. Invalidate `characterProfileProvider`
4. Refresh the combined Rewards state in place

## Trigger

`MainShell` checks `CharacterProfile.loginRewardAvailable` on app resume. If true and `_loginRewardShown == false` → show the dialog, set the flag.

## Related
- [[Login Rewards]]
- [[LoginReward]] (backend)
- [[Streak System]] (Day 3 shield grant)
- [[XP and Leveling]] (Day 7 XP Storm flag)
