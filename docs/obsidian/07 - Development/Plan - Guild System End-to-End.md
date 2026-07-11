---
tags: [lifelevel, plan, guild, social]
aliases: [Guild Plan, Guild Raids Plan]
---
# Plan — Guild System End-to-End

> Full guild lifecycle: create/join/manage guilds + guild raids with real-time HP/leaderboard via SignalR.

## Context

Guilds are the core social/co-op mechanic. A guild (≤5 players) fights bosses together — damage comes from each member's real workouts, the HP pool is shared, and members who slack trigger HP regeneration (accountability loop). The guild ring item has been a placeholder since the shell was built. This plan builds it fully.

**Key decisions:**
- Full lifecycle: create → join → manage → raids
- Guild leader triggers raids by picking a boss from the available pool
- Real-time updates via SignalR (live HP bar + member damage leaderboard)
- Max 5 members (matches mockup; configurable)

---

## Backend — New Module: `LifeLevel.Modules.Guild`

### Domain Entities

```
Domain/Entities/
├── Guild.cs                    — Id, Name, Description, OwnerId, MaxMembers=5, CreatedAt
├── GuildMember.cs              — Id, GuildId, UserId, Role (Leader/Member), JoinedAt
├── GuildRaid.cs                — Id, GuildId, BossId, StartedAt, ExpiresAt, TotalDamage, IsDefeated, IsExpired
└── GuildRaidContribution.cs    — Id, GuildRaidId, UserId, DamageDealt, LastActivityAt
```

### GuildService
- `CreateGuild(userId, name, description)` → creates Guild + GuildMember(Leader)
- `JoinGuild(userId, guildId)` → validates < MaxMembers, no existing membership
- `LeaveGuild(userId)` → transfer leadership if last leader; disband if last member
- `KickMember(requestingUserId, targetUserId)` → leader-only
- `GetMyGuild(userId)` → GuildDetailDto (members + active raid summary)
- `SearchGuilds(query)` → paginated list of open guilds

### GuildRaidService
- `StartRaid(guildId, bossId, leaderUserId)` → leader-only; creates GuildRaid + one GuildRaidContribution per member
- `DealDamage(userId, guildRaidId, activityId)` → reuses `BossService.CalculateDamageFromActivity()` (same formula); accumulates; broadcasts via SignalR; sets IsDefeated when maxHp crossed
- `GetRaidDetail(guildId)` → full raid state + contributions sorted by damage
- `ProcessSlackRegen(guildRaidId)` → called by DailyResetJob; for each member with LastActivityAt > 24h, regen 500 HP (subtract from TotalDamage, floor 0)

### Reuse from Existing Code
| What | Where |
|------|-------|
| `BossService.CalculateDamageFromActivity()` | `LifeLevel.Modules.Adventure.Encounters` |
| `ICharacterXpPort.AwardXpAsync()` | SharedKernel port |
| `ActivityLoggedEvent` | SharedKernel cross-module event — subscribe to auto-deal raid damage |

### SharedKernel Additions
- `IGuildQueryPort` — `Task<Guid?> GetActiveGuildIdAsync(Guid userId)` (for activity module cross-module routing)
- `GuildRaidDefeatedEvent` — fired on defeat → Achievements module hooks for raid achievements

### SignalR Hub
Hub: `GuildRaidHub` at `/hubs/guild-raid`, grouped by `raid-{guildRaidId}`

| Message | Payload | When |
|---------|---------|------|
| `RaidHpUpdated` | totalDamage, maxHp, contributions[] | after each damage hit |
| `RaidDefeated` | rewardXp, topDamageUserId | on defeat |
| `RaidExpired` | — | on timer expiry |
| `MemberSlacked` | userId, hpRegenAmount | on daily regen |

### API Endpoints (`/api/guild`)
```
POST   /api/guild                         create guild
GET    /api/guild/mine                    get my guild detail
GET    /api/guild/search?q=               search open guilds
POST   /api/guild/{guildId}/join          join
POST   /api/guild/leave                   leave
POST   /api/guild/{guildId}/kick/{userId} kick member (leader only)
POST   /api/guild/raid/start              start raid { bossId } (leader only)
GET    /api/guild/raid                    active raid detail
GET    /api/guild/raid/history            past raids
```

### AppDbContext + Migration
Add 4 DbSets. One migration `AddGuildSystem` with FK constraints and indexes on `(GuildId, UserId)` pairs.

Extend `DailyResetJob.cs` to call `GuildRaidService.ProcessSlackRegenForAllActiveRaids()`.

---

## Mobile — `features/guild/`

Follows the Boss feature folder pattern.

```
lib/features/guild/
├── models/
│   └── guild_models.dart              Guild, GuildMember, GuildRaid, GuildRaidContribution, GuildDetail
├── services/
│   ├── guild_service.dart             HTTP calls to GuildController
│   └── guild_raid_hub_service.dart    SignalR connection + event streams
├── providers/
│   └── guild_provider.dart            GuildNotifier, GuildRaidNotifier
├── screens/
│   ├── guild_screen.dart              hub: no-guild | guild home | active raid (inline, BossScreen pattern)
│   ├── guild_create_screen.dart       name + description form
│   └── guild_search_screen.dart       search + join list
└── widgets/
    ├── guild_no_guild_card.dart        "not in a guild" prompt — Create / Find buttons
    ├── guild_home_card.dart            guild name, member list, raid summary
    ├── guild_member_row.dart           avatar, name, role badge, damage (raid context)
    ├── guild_hp_bar.dart               shared HP bar — mirrors BossHpBar visual style
    └── guild_raid_card.dart            full raid view: boss info, HP bar, member leaderboard
```

### SignalR (Flutter)
- Add `signalr_netcore` to `pubspec.yaml` if not already present
- `GuildRaidHubService` connects to `{baseUrl}/hubs/guild-raid`, joins group for active raidId, exposes streams for `RaidHpUpdated`, `RaidDefeated`, `MemberSlacked`
- `GuildRaidNotifier` subscribes to streams → Riverpod watch triggers UI rebuild

### Shell Wiring
- `main_shell.dart` → add `'guild'` case in `_screenFor()` → `GuildScreen()`
- `_inferDeepLink()` → add guild notification deeplink → `lifelevel://guild`

---

## Build Order

1. Backend entities + AppDbContext + migration
2. GuildService + controller endpoints
3. GuildRaidService + ActivityLoggedEvent handler + XP awards
4. SignalR GuildRaidHub + broadcast calls
5. DailyResetJob slack regen extension
6. Mobile models + guild_service.dart
7. Mobile guild_raid_hub_service.dart
8. Mobile providers
9. Mobile screens + widgets
10. Shell wiring + notification deeplink

---

## Verification

- Create guild → verify Leader membership seeded
- Second user joins → membership record created
- Leader starts raid (any seeded boss) → GuildRaid + contributions created
- Both users log activities → TotalDamage accumulates, SignalR fires on both clients
- Two Flutter Chrome tabs connected to GuildRaidHub → HP bar updates live on both
- Debug-trigger slack regen → HP increases, `MemberSlacked` message received
- Defeat raid (deal full MaxHp damage) → XP awarded to all members, GuildRaidDefeatedEvent fires, raid achievements unlock

## Design Reference
- `design-mockup/guild-raids.html` — raid screen layout (HP bar segments, member leaderboard, SLACKING indicator, victory panel)

## Related
- [[Boss System]] — damage formula reuse, single-player boss baseline
- [[Feature - Boss]] — folder/pattern to mirror in mobile
- [[Shell and Radial FAB]] — guild ring item wiring
- [[Adventure.Encounters]] — backend module containing BossService
- [[Roadmap Status]] — Phase 8
