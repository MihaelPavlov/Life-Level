---
tags: [lifelevel, mobile]
aliases: [Login Reward Feature]
---
# Feature — Login Reward

> Shown as a dialog on app resume when a daily reward is available. Claim → XP + (sometimes) shield + (Day 7) XP Storm flag.

## Files

```
lib/features/login_reward/
├── login_reward_screen.dart
├── models/
│   └── login_reward_models.dart
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
Future<LoginRewardStatus> getStatus();        // GET /api/login-reward
Future<LoginRewardClaimResult> claim();       // POST /api/login-reward/claim
```

## Providers

```dart
final loginRewardStatusProvider = FutureProvider<LoginRewardStatus>(...);
final loginRewardProvider = FutureProvider<LoginRewardClaimResult>(...);  // fired on claim
```

## LoginRewardScreen

Dialog showing:
- Day indicator (e.g., "Day 5 of 7")
- XP reward amount (big)
- Shield icon if `includesShield`
- ⚡ XP Storm icon if `isXpStorm` (Day 7)
- Claim button

On claim:
1. Call `LoginRewardService().claim()`
2. If `leveledUp`: `LevelUpNotifier.instance.notify(newLevel)`
3. Invalidate `characterProfileProvider`
4. Auto-close dialog after animation

## Trigger

`MainShell` checks `CharacterProfile.loginRewardAvailable` on app resume. If true and `_loginRewardShown == false` → show the dialog, set the flag.

## Related
- [[Login Rewards]]
- [[LoginReward]] (backend)
- [[Streak System]] (Day 3 shield grant)
- [[XP and Leveling]] (Day 7 XP Storm flag)
