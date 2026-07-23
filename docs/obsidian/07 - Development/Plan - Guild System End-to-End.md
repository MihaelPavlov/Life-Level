---
tags: [lifelevel, plan, guild, social]
aliases: [Guild Plan, Guild Raids Plan, Guild MVP Plan]
---
# Plan - Guild System End-to-End

> Full target: create/join/manage guilds, start shared-HP guild raids, convert real workouts into guild damage, and show live guild progress in the mobile shell.

## Current Status

Guild is planned but not implemented.

Existing references:
- `docs/obsidian/02 - Game Design/Boss System.md` says guild raids are design-only.
- `docs/obsidian/04 - Mobile App/Shell and Radial FAB.md` lists Guild as a placeholder.
- `docs/board.md` has LL-016 for "Guild system + shared-HP raid boss".
- Mockups:
  - `design-mockup/guild/guild-system.html` - full 7-screen flow.
  - `design-mockup/boss/guild-raids.html` - active raid layout.

Current code:
- Backend has no `LifeLevel.Modules.Guild`.
- Mobile has no `mobile/lib/features/guild/`.
- Shell/ring already knows `guild`, but tapping it currently falls through to a placeholder.
- Boss damage formula already exists at `BossService.CalculateDamageFromActivity(...)`.
- Activity logging already publishes activity data and applies solo boss damage.

## Product Decisions

Ship the system in vertical slices. Do not start with real-time SignalR as the first deliverable.

MVP rules:
- One guild per user.
- Max 5 members.
- Guilds are open by default.
- Creator is `Leader`.
- Leader can start raids and kick members.
- Members can join, leave, and contribute damage.
- Only one active raid per guild.
- Workouts from any member damage the active guild raid.
- Raid damage uses the existing boss damage formula.
- Raid rewards are granted once when the shared HP reaches zero.

Deferred from MVP:
- Invite codes and private guilds.
- Friends-only guilds.
- Chat.
- Redis leaderboards.
- SignalR live updates.
- Push notifications for guild raid start.
- Complex guild ranks/seasons.

## Backend Module

Add new module:

```text
backend/src/modules/LifeLevel.Modules.Guild/
  Domain/
    Entities/
    Enums/
    Events/
  Application/
    DTOs/
    UseCases/
  Infrastructure/
    Persistence/Configurations/
    GuildModule.cs
```

Register it in `Program.cs` through `services.AddGuildModule()`.

Add `ApplyConfigurationsFromAssembly(typeof(GuildModule).Assembly)` and DbSets to `AppDbContext`.

## Backend Entities

```csharp
Guild
- Id
- Name
- Description
- Icon
- OwnerUserId
- MaxMembers
- IsOpen
- CreatedAt
- UpdatedAt

GuildMember
- Id
- GuildId
- UserId
- Role // Leader, Member
- JoinedAt

GuildRaid
- Id
- GuildId
- BossId
- StartedByUserId
- StartedAt
- ExpiresAt
- TotalDamage
- IsDefeated
- IsExpired
- DefeatedAt
- RewardClaimedAt

GuildRaidContribution
- Id
- GuildRaidId
- UserId
- DamageDealt
- LastActivityId
- LastActivityAt
```

Indexes:
- `GuildMember.UserId` unique for active membership.
- `GuildMember(GuildId, UserId)` unique.
- `GuildRaid(GuildId, IsDefeated, IsExpired)` to find active raids.
- `GuildRaidContribution(GuildRaidId, UserId)` unique.

## Backend Services

### GuildService

Responsibilities:
- Create guild.
- Get my guild detail.
- Search open guilds.
- Join guild.
- Leave guild.
- Kick member.
- Transfer leader on leader leave.
- Disband guild if the last member leaves.

Rules:
- A user cannot join/create a second guild.
- Full guild cannot be joined.
- Only leader can kick.
- Leader cannot kick themselves; they leave through `LeaveGuild`.
- If leader leaves and members remain, oldest member becomes leader.

### GuildRaidService

Responsibilities:
- List available raid bosses.
- Start raid.
- Get active raid detail.
- Get raid history.
- Apply activity damage.
- Expire old raids.
- Grant raid rewards.

Rules:
- Only leader starts a raid.
- One active raid per guild.
- Raid uses existing `Boss` catalog as source data for name/icon/maxHP/reward.
- Damage is capped at boss max HP.
- Contributions are per guild member.
- If raid is defeated, all current guild members get base reward XP.
- Top damage dealer gets bonus XP.
- No reward if raid expires.

Suggested reward rule:
- All members: `boss.RewardXp`.
- Top contributor: `boss.RewardXp * 0.25`, rounded.

Slack regen:
- Phase 1 can skip regen.
- Phase 2 adds daily regen: if a member has not contributed in 24h, subtract 500 from `TotalDamage`, floor 0, and record the event in logs/DTO.

## Shared Kernel Additions

Use ports/events to avoid module cycles.

```csharp
public interface IGuildRaidActivityPort
{
    Task<IReadOnlyList<GuildRaidDefeatedInfo>> ApplyActivityAsync(
        Guid userId,
        Guid activityId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        DateTime activityLoggedAt,
        CancellationToken ct = default);
}

public record GuildRaidDefeatedEvent(Guid GuildId, Guid GuildRaidId, Guid BossId) : IDomainEvent;
```

Activity module calls `IGuildRaidActivityPort` after normal activity persistence, similar to solo boss damage.

## API Endpoints

Controller: `GuildController`, route `/api/guild`, `[Authorize]`.

```text
GET    /api/guild/mine
POST   /api/guild
GET    /api/guild/search?q=&skip=&take=
POST   /api/guild/{guildId}/join
POST   /api/guild/leave
POST   /api/guild/{guildId}/kick/{userId}

GET    /api/guild/raid/bosses
POST   /api/guild/raid/start
GET    /api/guild/raid
GET    /api/guild/raid/history
POST   /api/guild/raid/debug/add-damage
POST   /api/guild/raid/debug/force-expire
```

Debug endpoints should be development/admin-only where possible.

## Mobile Feature

Add:

```text
mobile/lib/features/guild/
  models/guild_models.dart
  services/guild_service.dart
  providers/guild_provider.dart
  screens/guild_screen.dart
  screens/guild_create_screen.dart
  screens/guild_search_screen.dart
  screens/guild_raid_start_screen.dart
  widgets/guild_no_guild_card.dart
  widgets/guild_home_card.dart
  widgets/guild_member_row.dart
  widgets/guild_raid_card.dart
  widgets/guild_hp_bar.dart
  widgets/guild_victory_sheet.dart
```

Shell wiring:
- Import `GuildScreen`.
- Add `case 'guild': return const GuildScreen();`.
- Add `lifelevel://guild` deep-link handling.
- Ring item tap should open the Guild screen instead of placeholder.

Mobile states:
- Loading.
- Error/retry.
- No guild.
- Guild home, no active raid.
- Guild home with active raid.
- Search guilds.
- Create guild.
- Start raid.
- Raid victory.

Use the existing dark RPG visual language and mirror boss HP/progress patterns.

## SignalR Phase

Do not block MVP on this.

When the polling version works:
- Add SignalR server package if not already present.
- Add `GuildRaidHub` at `/hubs/guild-raid`.
- Group by `raid-{guildRaidId}`.
- Broadcast:
  - `RaidHpUpdated`
  - `RaidDefeated`
  - `RaidExpired`
  - `MemberSlacked`
- Add Flutter SignalR client service only after backend hub is stable.

## Implementation Order

### Phase 0 - Documentation and Decisions

- Confirm max members = 5.
- Confirm open guilds only for MVP.
- Confirm raid reward amounts.
- Confirm whether MVP includes slack regen. Recommendation: no, add in Phase 2.

### Phase 1 - Guild Lifecycle Backend

- Create module skeleton.
- Add entities/configurations.
- Add migration `AddGuildSystem`.
- Implement `GuildService`.
- Add `/api/guild` lifecycle endpoints.
- Add tests for create/join/leave/kick/search.

### Phase 2 - Guild Lifecycle Mobile

- Add `features/guild`.
- Add models/service/provider.
- Add no-guild, create, search, guild-home screens.
- Wire shell `guild` route.
- Verify create/join/leave from Flutter Chrome.

### Phase 3 - Raid Backend

- Add `GuildRaidService`.
- Add start/detail/history endpoints.
- Add `IGuildRaidActivityPort`.
- Wire `ActivityService.LogActivityAsync` and `LogExternalActivityAsync` to guild raid damage.
- Reuse `BossService.CalculateDamageFromActivity`.
- Add tests for start raid, member damage, non-member no-op, defeat, rewards, and one-active-raid rule.

### Phase 4 - Raid Mobile

- Add start raid screen.
- Add active raid card with HP bar and member damage ranking.
- Add victory sheet.
- Refresh guild provider after activity log success.
- Verify two users can contribute to the same raid.

### Phase 5 - Slack Regen and Expiry

- Extend `DailyResetJob` or add a guild raid background job.
- Expire raids after timer.
- Apply optional slack regen.
- Add tests for expiry and regen.
- Show slacking/expired states on mobile.

### Phase 6 - Live Updates

- Add SignalR hub.
- Add Flutter hub client.
- Replace or supplement polling refresh with live updates.
- Test with two Chrome tabs and two authenticated users.

## Verification Checklist

- User A creates guild and becomes Leader.
- User B searches and joins.
- User B cannot join a second guild.
- User A starts a raid.
- User B cannot start a raid unless leader.
- Manual workout by User A damages raid.
- External synced workout by User B damages raid.
- Damage contribution rows update independently.
- Raid defeat grants XP once.
- Top contributor gets bonus XP once.
- Mobile Guild ring opens actual Guild screen.
- Mobile no-guild/create/search/guild-home/active-raid/victory states render without overflow.
- Backend tests pass.
- Flutter analyze passes.

## Open Questions

- Should guild raids use the same boss catalog as solo bosses, or a separate raid boss catalog?
- Should joining a guild require approval/invite in v1?
- Should inactive members reduce raid rewards, or only trigger regen?
- Should raid rewards grant items/titles/achievements in MVP?
- Should guild membership use `UserId` only, or also snapshot character display info for history?

## Recommended MVP Scope

Build Phases 1-4 first.

This gives a complete player-visible loop:

```text
Create guild -> join guild -> start raid -> log workouts -> shared HP drops -> raid defeated -> rewards shown
```

Then add Phase 5 slack regen and Phase 6 SignalR once the core persistence and mobile surfaces are stable.

## Related

- [[Boss System]]
- [[Shell and Radial FAB]]
- [[Feature - Boss]]
- [[Roadmap Status]]
- `docs/board.md` LL-016
