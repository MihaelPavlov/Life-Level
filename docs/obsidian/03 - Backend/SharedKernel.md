---
tags: [lifelevel, backend]
aliases: [LifeLevel.SharedKernel, Cross-Module Ports]
---
# SharedKernel

> The contracts-only module. Every other module depends on SharedKernel and SharedKernel depends on no one. All cross-module communication happens through interfaces defined here.

## Contents

```
SharedKernel/
├── Contracts/
│   ├── IUserContext.cs             ← current userId from HTTP context
│   └── ICurrentClock.cs            ← DateTime.UtcNow abstraction (testability)
├── Abstractions/
│   └── Result.cs                   ← Result<T> — avoid exceptions as flow control
├── Events/
│   ├── IDomainEvent.cs
│   ├── IEventHandler.cs
│   ├── IEventPublisher.cs
│   └── InProcessEventPublisher.cs
├── Ports/                           ← cross-module port interfaces, implemented by owner modules
│   └── (see full catalog below)
└── Enums/
    ├── UserRole.cs                 ← Player, Admin
    └── ActivityType.cs             ← shared by Activity + Quest
```

## Cross-module ports (full catalog)

### Character ports (implemented by [[Character]])

| Interface | Method | Purpose |
|-----------|--------|---------|
| `ICharacterXpPort` | `AwardXpAsync(userId, source, emoji, description, xp)` | Award XP + write history entry + trigger level-up check |
| `ICharacterStatPort` | `ApplyStatGainsAsync(userId, StatGains)` | Apply stat deltas (capped at 100) |
| `ICharacterLevelReadPort` | `GetLevelAsync(userId)` | Current level |
| `ICharacterInfoPort` | `GetByUserIdAsync(userId)` | `CharacterInfoDto(Id, IsSetupComplete)` |
| `ICharacterIdReadPort` | `GetCharacterIdAsync(userId)` | Resolve character GUID from user |
| `IInventorySlotReadPort` | `GetMaxInventorySlotsAsync(userId)` | Max slots (scales with level) |

### Streak ports (implemented by [[Streak]])

| Interface | Method | Purpose |
|-----------|--------|---------|
| `IStreakReadPort` | `GetCurrentStreakAsync(userId)` | `StreakReadDto(Current, Longest, ShieldsAvailable)` |
| `IStreakShieldPort` | `AddShieldAsync(userId)` | Grant a streak shield (used by LoginReward) |
| `IStreakDailyReset` | `CheckAndBreakExpiredStreaksAsync` + `ResetShieldUsedTodayFlagsAsync` | Midnight cron tasks |

### Quest ports (implemented by [[Quest]])

| Interface | Method | Purpose |
|-----------|--------|---------|
| `IDailyQuestReadPort` | `CountCompletedDailyQuestsAsync(userId)` | Today's completed-daily count |
| `IQuestProgressPort` | `UpdateProgressFromActivityAsync(userId, type, duration, distance, calories)` | Advance quest progress from an activity |

### Login Reward ports (implemented by [[LoginReward]])

| Interface | Method | Purpose |
|-----------|--------|---------|
| `ILoginRewardReadPort` | `HasClaimedTodayAsync(userId)` | Claim-available check |
| `ILoginRewardDailyReset` | `ResetDailyClaimFlagsAsync` | Midnight reset |

### Map ports (implemented by [[Map]])

| Interface | Method | Purpose |
|-----------|--------|---------|
| `IMapProgressReadPort` | `GetCurrentNodeIdAsync(userId)` | Current node for boss/chest gating |
| `IMapDistancePort` | `AddDistanceAsync(userId, km)` | Credit km toward map travel |
| `IMapNodeCountPort` | `GetNodeCountsByZoneIdsAsync(zoneIds)` | Total nodes per zone |
| `IMapNodeCompletedCountPort` | `GetCompletedNodeCountsByZoneIdsAsync(userId, zoneIds)` | Completed nodes per zone |

### Items ports (implemented by [[Items]])

| Interface | Method | Purpose |
|-----------|--------|---------|
| `IGearBonusReadPort` | `GetEquippedBonusesAsync(userId)` | `GearBonusesDto(XpBonusPct, Str/End/Agi/Flx/StaBonus)` |

### Activity ports (implemented by [[Activity]])

| Interface | Method | Purpose |
|-----------|--------|---------|
| `IActivityLogPort` | `LogExternalActivityAsync(...)` | Ingest activity from external source (Strava, Health Connect) |
| `IActivityExternalIdReadPort` | `FindActivityIdByExternalIdAsync(characterId, externalId)` | Dedup check |
| `IActivityStatsReadPort` | `GetWeeklyStatsAsync(userId)` | `WeeklyActivityStatsDto(Runs, DistanceKm, XpEarned)` |

### Identity ports (implemented by [[Identity]])

| Interface | Method | Purpose |
|-----------|--------|---------|
| `IUserReadPort` | `GetUsernameAsync(userId)` | Username for profile display (implemented via adapter in Api that bridges Identity → Character lookup) |

### Notification ports (implemented by Notifications module — see [[LL-013]] / LL-013a)

| Interface | Method | Purpose |
|-----------|--------|---------|
| `INotificationPort` | `SendToUserAsync(userId, category, title, body, data?, isCritical=false)` | Send a push to all active device tokens; applies quiet-hours + daily-cap cadence policy. Returns `NotificationSendResult(Sent, Reason)` |

## Why ports live here (not in each module)

Test projects only need to reference `SharedKernel` to mock any port — no pulling the entire `Character` module into an `Activity` test project.

## Related
- [[Architecture Overview]]
- [[Cross-Module Events]]
- Every `[[<Module>]]` note shows which ports it implements/consumes
