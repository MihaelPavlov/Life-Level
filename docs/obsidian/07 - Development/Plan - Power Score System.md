---
tags: [lifelevel, plan, character, combat, power]
aliases: [Power Plan, Power Score Plan, Combat Power Plan]
---
# Plan - Power Score System

> Add a single derived "Power" number to the Character that (a) summarizes how strong a character is for cross-user comparison, and (b) scales combat damage output in boss fights, mini-bosses, and guild raids.

## Context

The user asked for a "Power" property: a single number summarizing how strong
a character is, usable to compare different users. Two design questions were
resolved directly with the user before planning:

1. **Power is not cosmetic-only** — it must also scale combat damage output
   (solo boss fights, mini-bosses, and guild raids), as a multiplier on top of
   the existing purely-activity-based damage formula.
2. **Power's inputs**: `Character.Level`, the 5 core stats (STR/END/AGI/FLX/STA)
   *including* equipped gear bonuses, plus a prestige component from
   Rank/bosses-defeated.

## Current Status

Not implemented. This is a green-field addition — no "Power" concept exists
anywhere in the docs vault (checked all 78 files in `docs/obsidian/`), the
backend, or the mobile app.

Existing references:
- Both `design-mockup/canvas-command-center/Main.dc.html` and
  `design-mockup/canvas-worldmap/Main.dc.html` already reserve a UI slot for
  it — a "LOADOUT HERO" section with 5 stat gems + a right-aligned "Power"
  label/number (placeholder `1,240` for a Level-3 character with stats
  summing to 43). Not implemented in Flutter — the real `HomeHeader`
  (`mobile/lib/features/home/cards/home_header.dart`) is a simple
  avatar+greeting+streak row with no stat gems.
- Boss/raid damage today is **purely activity-based**, with zero coupling to
  Character stats. The single formula,
  `BossService.CalculateDamageFromActivity`
  (`backend/src/modules/LifeLevel.Modules.Adventure.Encounters/Application/UseCases/BossService.cs:243`):
  ```csharp
  baseDamage = calories*0.5 + durationMinutes*1.0 + distanceKm*3.0
  damage = (int)(baseDamage * activityTypeMultiplier)  // 0.8–1.3
  ```
  is called from exactly 3 places, each computing `damage` as a plain local
  `int` immediately before handing it to a "deal damage" call — this makes
  multiplier insertion a one-line change at each site:
  - `ActivityBossDamageAdapter.ApplyAsync` (line 43) → `bossService.DealDamageAsync(userId, bossId, damage)`
  - `GuildService.ApplyActivityAsync` (line 564) → `ApplyDamageAsync(userId, raid, damage, ...)`
  - `BossController` debug endpoint (~line 79) → same pattern

## Architecture Constraints (checked against real code)

- Cross-module contracts live in `LifeLevel.SharedKernel/Ports/` (not inside
  the consumer module) — e.g. `IGearBonusReadPort`/`GearBonuses` already
  lives there.
- **`CharacterService` cannot take a direct dependency on `IGearBonusReadPort`.**
  `IGearBonusReadPort` is implemented by `ItemService`, which itself depends
  on ports implemented by `CharacterService` — a direct dependency would form
  the same class of DI cycle already called out in a comment at the top of
  `BossService.cs` (re: `IActivityHistoryReadPort`). This is exactly why
  `CharacterController.GetProfile` today fetches gear bonuses separately and
  merges them (`profile with { GearBonuses = gearBonuses }`) rather than
  having `CharacterService` do it internally — confirmed by reading
  `CharacterController.cs:41-63`.
- Existing SharedKernel ports checked and confirmed **not reusable**:
  `ICharacterStatPort` is write-only (`ApplyStatGainsAsync`);
  `ICharacterLevelReadPort` returns only Level (no stats). A new read port is
  needed for "current level + 5 stats".
- Precedent for resolving a port at the API composition root (used when no
  single module can own all the required inputs without a cycle):
  `IUserReadPort` → `UserReadPortAdapter`
  (`backend/src/LifeLevel.Api/Application/Adapters/UserReadPortAdapter.cs`),
  registered in `Program.cs:101-103`. This plan follows that exact pattern.

## Power Formula

Pure, dependency-free, single source of truth — new file:
`backend/src/modules/LifeLevel.SharedKernel/Calculators/CharacterPowerCalculator.cs`

```csharp
namespace LifeLevel.SharedKernel.Calculators;

public static class CharacterPowerCalculator
{
    public const int BaseFloor = 100;
    public const int LevelWeight = 20;
    public const int StatWeight = 25;
    public const int BossWeight = 40;

    public const double MultiplierSlope = 0.0005;
    public const double MaxDamageMultiplier = 4.0;

    /// Power at a fresh Level-1, zero-stat, zero-boss character — the floor
    /// the damage multiplier is anchored to (multiplier == 1.0 exactly here).
    public const int PowerFloor = BaseFloor + LevelWeight;

    public static int CalculatePower(int level, int totalEffectiveStats, int bossesDefeated) =>
        BaseFloor + LevelWeight * level + StatWeight * totalEffectiveStats + BossWeight * bossesDefeated;

    public static double CalculateDamageMultiplier(int power) =>
        Math.Clamp(1.0 + Math.Max(0, power - PowerFloor) * MultiplierSlope, 1.0, MaxDamageMultiplier);
}
```

- `totalEffectiveStats` = own STR+END+AGI+FLX+STA **plus** equipped
  `GearBonuses.StrBonus/EndBonus/AgiBonus/FlxBonus/StaBonus` (excludes
  `XpBonusPct`, which is unrelated to combat power).
- **Rank is deliberately not a separate weighted term** — `Character.Rank` is
  100% derived from `BossesDefeated` via admin-editable `RankThreshold` rows,
  so weighting it separately would double-count the same signal off a
  fragile, admin-mutable name→ordinal mapping. `BossesDefeated` alone is the
  robust "prestige" input.
- **Calibration**: Level 3, stats summing 43, 0 bosses (the mockup's example)
  → `100 + 60 + 1075 + 0 = 1235`, within 0.4% of the mockup's placeholder
  `1,240`. Fresh signup (L1, 0 stats, 0 bosses) → `120`. Rough endgame
  (L80, ~600 effective stats, ~120 bosses) → `≈21,500` — early game sits in
  3–4 digits, endgame reaches tens of thousands.
- **Damage multiplier**: exactly `1.0x` at the floor (today's balance
  unchanged for new characters), rising with `MultiplierSlope`, clamped at
  `MaxDamageMultiplier = 4.0x` (reached around `Power ≈ 6120`) so late-game
  combat can't trivialize. All 6 constants live in this one file for easy
  retuning.

## Cross-Module Wiring

New port, in `LifeLevel.SharedKernel/Ports/`:

```csharp
// ICharacterStatsSnapshotReadPort.cs
public record CharacterStatsSnapshot(int Level, int Strength, int Endurance, int Agility, int Flexibility, int Stamina);
public interface ICharacterStatsSnapshotReadPort
{
    Task<CharacterStatsSnapshot?> GetStatsAsync(Guid userId, CancellationToken ct = default);
}

// ICharacterPowerReadPort.cs
public interface ICharacterPowerReadPort
{
    Task<double> GetDamageMultiplierAsync(Guid userId, CancellationToken ct = default);
}
```

- `ICharacterStatsSnapshotReadPort` is implemented directly by
  `CharacterService` (zero new constructor dependencies added there → no
  cycle risk).
- `ICharacterPowerReadPort` is implemented by a **new composition-root
  adapter**, `backend/src/LifeLevel.Api/Application/Adapters/CharacterPowerAdapter.cs`,
  exactly mirroring `UserReadPortAdapter`. It composes three existing/new
  ports — `ICharacterStatsSnapshotReadPort` (Character), `IGearBonusReadPort`
  (Items), `IBossDefeatedCountReadPort` (Encounters, DbContext-only adapter,
  no risk of cycling back) — calls `CharacterPowerCalculator`, and is
  registered once in `Program.cs` next to the `IUserReadPort` registration.
- `BossService`, `ActivityBossDamageAdapter`, and `GuildService` each take a
  plain constructor dependency on `ICharacterPowerReadPort` and call
  `GetDamageMultiplierAsync(userId)` right where `damage` is currently
  computed, multiplying the result before passing it on. Verified no DI
  cycle: nothing in `CharacterPowerAdapter`'s dependency chain resolves back
  to `BossService`/`ActivityBossDamageAdapter`/`GuildService`.
- One port, consumed directly by both Boss and Guild call sites (not routed
  through the Activity module as a threaded parameter) — mirrors how
  `IGearBonusReadPort` is already consumed independently by two different
  callers (`ActivityService` and `CharacterController`).

## No EF Core Migration

Power is pure on-demand arithmetic over already-loaded data — no new column,
no schema change. This mirrors how `xpProgress`/`xpRemaining` are already
computed client-side rather than persisted. Persisting a `Power` column would
require keeping it in sync across 4 separate write paths (stat spend,
level-up, gear change, boss kill) for no real benefit given how cheap it is
to derive on read.

## Files To Add

- `backend/src/modules/LifeLevel.SharedKernel/Calculators/CharacterPowerCalculator.cs`
- `backend/src/modules/LifeLevel.SharedKernel/Ports/ICharacterStatsSnapshotReadPort.cs`
- `backend/src/modules/LifeLevel.SharedKernel/Ports/ICharacterPowerReadPort.cs`
- `backend/src/LifeLevel.Api/Application/Adapters/CharacterPowerAdapter.cs`

## Files To Modify

**Backend**
- `backend/src/modules/LifeLevel.Modules.Character/Application/UseCases/CharacterService.cs`
  — implement `ICharacterStatsSnapshotReadPort.GetStatsAsync`; in
  `GetProfileAsync`, forward `ctx.BossesDefeated` (currently dropped) into the
  response and set `Power` from the character's own Level+stats (gear is
  merged downstream, same place `GearBonuses` is merged today).
- `.../LifeLevel.Modules.Character/Application/DTOs/CharacterProfileResponse.cs`
  — add `int Power` field.
- `backend/src/LifeLevel.Api/Controllers/CharacterController.cs` — in
  `GetProfile`, after the existing `gearBonuses` fetch/merge line, recompute
  `Power` including gear bonuses via `CharacterPowerCalculator.CalculatePower`
  and merge into `result`.
- `.../LifeLevel.Modules.Character/Infrastructure/CharacterModule.cs` (DI
  registration file) — register
  `services.AddScoped<ICharacterStatsSnapshotReadPort>(sp => sp.GetRequiredService<CharacterService>());`
- `backend/src/LifeLevel.Api/Program.cs` — register
  `builder.Services.AddScoped<ICharacterPowerReadPort, CharacterPowerAdapter>();`
  after Character/Items/Encounters registrations.
- `.../LifeLevel.Modules.Adventure.Encounters/Application/UseCases/BossService.cs`
  — inject `ICharacterPowerReadPort`; apply the multiplier in
  `GetDamageHistoryAsync`'s recompute-on-read loop (display only, `HpDealt`
  stays the source of truth for actual HP state).
- `.../LifeLevel.Modules.Adventure.Encounters/Infrastructure/ActivityBossDamageAdapter.cs`
  — inject `ICharacterPowerReadPort`; multiply `damage` (line 43-44) before
  the per-boss `DealDamageAsync` loop.
- `.../LifeLevel.Modules.Guild/Application/UseCases/GuildService.cs` — inject
  `ICharacterPowerReadPort`; multiply `damage` at line 564 before
  `ApplyDamageAsync`.
- `backend/src/LifeLevel.Api/Controllers/BossController.cs` — apply the same
  multiplier in the debug activity-damage endpoint (~line 79) for consistency,
  including both raw and final damage in the debug response.

**Mobile**
- `mobile/lib/features/character/models/character_profile.dart` — add
  `final int power;` + `fromJson` parsing (`json['power'] as int? ?? 0` for
  backward compatibility).
- `mobile/lib/features/home/cards/home_header.dart` — add a compact
  right-aligned "Power" label+number next to the existing avatar/name row
  (small addition, not a full "loadout hero" rebuild), wired from `profile.power`.
- `mobile/lib/features/profile/profile_overview_tab.dart` — surface
  `profile.power` near the existing "CORE STATS" section header for
  consistency.

## Verification

1. **Floor check**: fresh test user (L1, 0 stats, 0 bosses) — `GET /api/character/me`
   → `Power == 120`. Trigger a fixed activity (`running, 30min, 5km, 300cal`)
   against an active boss fight and confirm resulting damage equals the
   **pre-change** formula's output for the same inputs (multiplier exactly 1.0x).
2. **Progression check**: spend stat points / level up the same character,
   re-fetch profile, confirm `Power` increased per the formula, then repeat
   the fixed activity and confirm damage is now strictly higher, matching
   `baseDamage * CharacterPowerCalculator.CalculateDamageMultiplier(power)`.
3. **Cross-module consistency**: same user, same instant — confirm the solo
   boss path and the guild-raid path apply the identical multiplier for the
   same activity.
4. **Clamp check**: confirm multiplier never exceeds 4.0x regardless of how
   high Power goes.
5. **Gear-bonus check**: equip an item with nonzero stat bonuses, confirm
   `Power` in `/api/character/me` increases by `StatWeight * bonus sum` with
   no stat/level change.
6. **Mobile**: confirm `CharacterProfile.power` deserializes from a live
   response and renders in the updated Home header / Profile overview tab.
