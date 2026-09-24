# Plan - Guild Redesign

Source: Claude Artifact "Guild Hall Redesign" (https://claude.ai/artifact/CUmcvPmVLgaKH99uZeG1m9) built from the new guild reference art.

## Scope
Restyle the existing Guild feature (`mobile/lib/features/guild/`) to the new design using **only data the backend already returns**. No backend changes in this pass.

## Screens
| Mode | Screen | Notes |
|------|--------|-------|
| `home` | Guild Hall | Castle hero, banner crest, name/motto, tags, hub tiles, current raid card, members preview |
| `raid` | Guild Raid | Boss hero, shared HP bar, your damage, contribution leaderboard, rewards |
| `members` | Members | Role badges, raid damage bars, open seats, role permission table |
| `startRaid` / `history` | Boss picker / raid history | Restyled with the new card language |
| `create` / `edit` | Guild settings | Live crest preview, crest picker, name, description |
| `search` / no guild | Find a Guild | Search + guild cards |

## Data mapping
- **Live now:** name, description, icon, memberCount/maxMembers, isOpen, viewerRole, permission flags, members (role, raidDamage), activeRaid (boss, HP, timer, guildSizeAtStart, rewardXp, contributions, MVP), raid history.
- **Not built (omitted from UI, not faked):** guild level/XP, weekly contribution, guild rank, chat, guild shop, activity feed, online status, member level/XP, invite links, language/focus tags.

## Role permissions (from `GuildService`)
- Leader: manage raids, manage all members, edit guild.
- Officer: manage raids, remove regular members only.
- Member: none.

## Structure
- `widgets/guild_widgets.dart` - shared building blocks (crest, top bar, cards, pills, HP bar, avatar)
- `screens/guild_screen.dart` - state/mode controller
- `screens/guild_home_view.dart`, `guild_raid_view.dart`, `guild_members_view.dart`, `guild_find_views.dart`

## Assets
`mobile/assets/Guild/` - cropped from the reference art (castle hero x2). Registered in `pubspec.yaml`, referenced via `AppIcons`.

## Follow-ups (need backend)
Guild XP/levels, weekly contribution + rank, chat, shop, activity feed, presence, invite links, search filters.
