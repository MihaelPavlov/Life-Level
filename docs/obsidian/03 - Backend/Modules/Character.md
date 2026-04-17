---
tags: [lifelevel, backend]
aliases: [Character Module, CharacterService]
---
# Character

> The heart of the game — owns character stats, XP, level, rank, class, titles, and the XP history log.

## Entities

### Character
```csharp
class Character {
  Guid Id, UserId;
  int Level = 1;
  long Xp = 0;
  Rank Rank = Novice;
  int Strength = 0, Endurance = 0, Agility = 0, Flexibility = 0, Stamina = 0;
  int AvailableStatPoints = 0;
  int MaxInventorySlots;           // computed from level (20–100)
  Guid? ClassId;
  string? AvatarEmoji;
  bool IsSetupComplete = false;
  Guid? EquippedTitleId;
}
```

### CharacterClass
```csharp
class CharacterClass {
  Guid Id;
  string Name, Emoji, Description, Tagline;
  float StrMultiplier, EndMultiplier, AgiMultiplier, FlxMultiplier, StaMultiplier;  // each default 1.0
  bool IsActive;
}
```

### XpHistoryEntry
```csharp
class XpHistoryEntry {
  Guid Id, CharacterId;
  string Source, SourceEmoji, Description;
  int Xp;
  DateTime EarnedAt;
}
```

Keeps the **last 50** entries per character (older entries pruned).

### Title + CharacterTitle
Title templates and earned titles. See [[Achievements and Titles]].

## CharacterService (implements 6 ports)

Implements: `ICharacterXpPort`, `ICharacterStatPort`, `ICharacterLevelReadPort`, `ICharacterInfoPort`, `ICharacterIdReadPort`, `IInventorySlotReadPort`.

Key methods:

- `GetAllClassesAsync()` → list of active classes
- `SetupAsync(userId, CharacterSetupRequest)` — class + avatar; grants **+500 XP starter bonus**
- `GetProfileAsync(userId, CharacterProfileContext)` → `CharacterProfileResponse` (full profile: weekly stats, streak, login-reward availability, completed-daily-quest count)
- `SpendStatPointAsync(userId, stat)` — **+5** to chosen stat (cap 100)
- `GetXpHistoryAsync(userId)` — last 50 entries
- `AwardXpAsync(...)` — writes history entry, calls `CheckAndApplyLevelUpsAsync`
- `ApplyStatGainsAsync(userId, StatGains)` — caps each stat at 100
- `CheckAndApplyLevelUpsAsync(characterId)` — loops while XP ≥ next-level threshold; publishes `CharacterLeveledUpEvent(userId, prev, new)`

## XP curve formula

```csharp
private static long XpAtLevelStart(int level) =>
    (long)level * (level - 1) / 2 * 300;
```

See [[XP and Leveling]] for the full table.

## Inventory slot scaling (`IInventorySlotReadPort`)

```
L 1–4   →  20 slots
L 5–9   →  30
L 10–14 →  40
L 15–24 →  50
L 25–34 →  60
L 35–49 →  75
L 50+   → 100
```

## TitleService

- `CheckAndGrantTitlesAsync(userId)` — evaluates:
  - Rank thresholds: Novice=0, Warrior=10, Champion=25, Legendary=50 bosses
  - Criteria strings against `{bossCount, streakDays, questCount, rankName}`
- Grants matching titles + equips the highest-tier if none equipped.

## TitleGrantHandler

`IEventHandler<CharacterLeveledUpEvent>` — re-runs `CheckAndGrantTitlesAsync` on every level-up.

## CharacterCreatedHandler

`IEventHandler<UserRegisteredEvent>` — creates the initial `Character` row (default stats, `IsSetupComplete = false`) when a user registers.

## Ports implemented
- `ICharacterXpPort`, `ICharacterStatPort`, `ICharacterLevelReadPort`
- `ICharacterInfoPort`, `ICharacterIdReadPort`, `IInventorySlotReadPort`

## Ports consumed
- `IEventPublisher`
- `IStreakReadPort`, `ILoginRewardReadPort`, `IDailyQuestReadPort`, `IActivityStatsReadPort`, `IGearBonusReadPort` (for profile assembly)

## Events raised
- `CharacterLeveledUpEvent(userId, previousLevel, newLevel)`

## Endpoints
- `POST /api/character/setup`
- `GET /api/character/me`
- `GET /api/character/xp-history`
- `POST /api/character/spend-stat`
- `GET /api/classes`
- `GET /api/titles`
- `POST /api/titles/{titleId}/equip`

## Files
- `backend/src/modules/LifeLevel.Modules.Character/`

## Related
- [[Character System]]
- [[XP and Leveling]]
- [[Achievements and Titles]]
- [[Identity]]
- [[Cross-Module Events]]
