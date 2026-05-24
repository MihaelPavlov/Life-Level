# Plan: Level-Up Messages, Boss History & Combined Deploy Script

**Status:** Pending implementation

---

## Context

Three independent improvements identified after the notification system was fixed and tested:
1. Level-up push notification always says "New zones unlocked!" but zones only unlock at ~11 specific levels — misleading at most level-ups. Overlay eyebrow also says "RANK UP" which conflicts with the game's separate Rank system.
2. Boss history (DEFEATED / EXPIRED sections + RECENT HITS damage log) exists in code but needs timestamp lines to be clearly distinguishable, and backend damage-history endpoint needs verification.
3. AAB and backend are built by two separate manual steps. A single script should build both and print exactly what to paste where.

---

## Fix 1 — Level-Up Notification Body + Overlay Eyebrow

### Backend — smart notification body
**File:** `backend/src/modules/LifeLevel.Modules.Notifications/Application/EventHandlers/LevelUpNotificationHandler.cs`

Zone unlocks only happen at levels: `1, 8, 15, 25, 32, 38, 44, 50, 56, 62, 68, 72, 76, 80, 85` (from `WorldSeedData.cs`). The handler already receives `e.NewLevel`:

```csharp
private static readonly HashSet<int> ZoneUnlockLevels =
    new() { 1, 8, 15, 25, 32, 38, 44, 50, 56, 62, 68, 72, 76, 80, 85 };

var body = ZoneUnlockLevels.Contains(e.NewLevel)
    ? $"You reached Level {e.NewLevel}. A new region is now unlocked!"
    : $"You reached Level {e.NewLevel}. Keep pushing — more unlocks ahead!";
```

Replace the hardcoded body `"New zones unlocked!"` in `SendToUserAsync(...)`.

### Flutter — overlay eyebrow text
**File:** `mobile/lib/core/widgets/level_up_overlay.dart` line 99

Change `'✦ RANK UP ✦'` → `'✦ LEVEL UP ✦'`

"Rank" in the game is a separate concept (Novice → Warrior → Veteran → Champion → Legend); this overlay is about the numeric level.

---

## Fix 2 — Boss History Cards: Add Timestamp Lines

DEFEATED and EXPIRED sections render correctly when data exists, but the cards look similar to active cards without a clear time reference.

**File:** `mobile/lib/features/boss/widgets/boss_defeated_card.dart`
- Add secondary line: `"Defeated {_timeAgo(boss.defeatedAt)}"` when `boss.defeatedAt != null`

**File:** `mobile/lib/features/boss/widgets/boss_expired_card.dart`
- Add secondary line: `"Expired {_timeAgo(boss.timerExpiresAt)}"` when `boss.timerExpiresAt != null`

**New file:** `mobile/lib/features/boss/utils/boss_time_utils.dart`
- Extract shared `timeAgo(DateTime?)` helper (same logic already exists inline in `boss_damage_hit_row.dart`)

**Also verify:** confirm `GET /boss/{bossId}/damage-history` is present on the deployed Render backend. If missing, the RECENT HITS section will always show empty (404 → silently empty by design in `boss_page_service.dart`).

---

## Fix 3 — Combined Deploy Script

**New file:** `deploy-all.ps1` at the repo root (`Life-Level/`).

### Behaviour
- Default: builds **both** backend and mobile.
- Flags `-SkipBackend` and `-SkipMobile` skip either step.
- Before building the AAB: auto-increments the `+N` build number in `mobile/pubspec.yaml` (e.g. `1.0.0+10` → `1.0.0+11`).
- Calls existing `backend\deploy.ps1` and captures output to extract the Docker image tag.
- Runs `flutter build appbundle --release --dart-define=API_BASE_URL=https://life-level-api-latest-1779363121.onrender.com/api` from `mobile\`.
- Prints summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  DEPLOY SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Backend image : mpavlov9905/life-level-api:latest.XXXX
  → Render: set Docker image tag, then Manual Deploy

  AAB (v1.0.0+11): mobile\build\app\outputs\bundle\release\app-release.aab
  → Play Console: upload as new internal testing release
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Files to Change

| File | Change |
|------|--------|
| `backend/.../EventHandlers/LevelUpNotificationHandler.cs` | Smart body based on zone-unlock level set |
| `mobile/lib/core/widgets/level_up_overlay.dart` | Eyebrow `"RANK UP"` → `"LEVEL UP"` |
| `mobile/lib/features/boss/widgets/boss_defeated_card.dart` | Add `defeatedAt` timestamp line |
| `mobile/lib/features/boss/widgets/boss_expired_card.dart` | Add `timerExpiresAt` timestamp line |
| `mobile/lib/features/boss/utils/boss_time_utils.dart` (new) | Shared `timeAgo` helper |
| `deploy-all.ps1` (new, repo root) | Combined build + summary script |

Backend change requires rebuild + Render redeploy.
Flutter changes require new AAB (version bump handled by script).

---

## Verification

1. **Notification body**: level up to a non-zone level (e.g. 3) → push says "Keep pushing". Level up to 8 → push says "A new region is now unlocked!"
2. **Overlay**: level-up overlay shows `"✦ LEVEL UP ✦"` not `"✦ RANK UP ✦"`
3. **Boss history**: defeat or expire a test boss → card appears under DEFEATED/EXPIRED with timestamp line ("Defeated 2 min ago")
4. **Deploy script**: `.\deploy-all.ps1` from repo root → builds both, prints summary. `.\deploy-all.ps1 -SkipBackend` → only builds AAB with auto-incremented version.
