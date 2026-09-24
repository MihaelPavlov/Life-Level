import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../models/guild_models.dart';
import '../providers/guild_provider.dart';
import '../widgets/guild_widgets.dart';
import 'guild_members_view.dart';

String guildTimeLeft(Duration d) {
  if (d.isNegative || d == Duration.zero) return 'Ended';
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m';
}

enum GuildMenuAction { edit, leave, delete }

/// Guild Hall: castle hero + crest, hub tiles, current raid, members preview.
class GuildHomeView extends StatelessWidget {
  final GuildDetail guild;
  final VoidCallback onBack;
  final VoidCallback onMembers;
  final VoidCallback onRaid;
  final VoidCallback onHistory;
  final VoidCallback? onStartRaid;
  final VoidCallback? onEdit;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  const GuildHomeView({
    super.key,
    required this.guild,
    required this.onBack,
    required this.onMembers,
    required this.onRaid,
    required this.onHistory,
    required this.onStartRaid,
    required this.onEdit,
    required this.onLeave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final raid = guild.activeRaid;
    final maxDamage = guild.members
        .fold<int>(0, (best, m) => m.raidDamage > best ? m.raidDamage : best);
    final preview = guild.members.take(3).toList();
    final openSeats = (guild.maxMembers - guild.members.length).clamp(0, 2);

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () async {
        final container = ProviderScope.containerOf(context, listen: false);
        await container.read(guildProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _Hero(guild: guild, onBack: onBack, menu: _menu(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HubTile(
                        icon: Icons.groups_rounded,
                        label: 'Members',
                        onTap: onMembers,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HubTile(
                        icon: Icons.sports_martial_arts_rounded,
                        label: 'Raid',
                        hot: raid != null,
                        badge: raid != null,
                        onTap: onRaid,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HubTile(
                        icon: Icons.history_rounded,
                        label: 'History',
                        onTap: onHistory,
                      ),
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HubTile(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          onTap: onEdit!,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (raid == null)
                  _NoRaidCard(onStartRaid: onStartRaid, onHistory: onHistory)
                else
                  _RaidCard(raid: raid, onOpen: onRaid),
                GuildSectionHeader(
                  'Members',
                  count: '(${guild.memberCount}/${guild.maxMembers})',
                  actionLabel: 'See all',
                  onAction: onMembers,
                ),
                for (final member in preview)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GuildMemberCard(
                      member: member,
                      maxDamage: maxDamage,
                      compact: true,
                    ),
                  ),
                for (var i = 0; i < openSeats; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GuildOpenSeat(
                      label: guild.isOpen
                          ? 'Open seat - anyone can join'
                          : 'Open seat - invite only',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return PopupMenuButton<GuildMenuAction>(
      popUpAnimationStyle: AppMotion.animationStyle(
        context,
        enter: AppMotionTokens.micro,
        exit: AppMotionTokens.pressUp,
      ),
      tooltip: 'Guild actions',
      color: AppColors.surfaceElevated,
      padding: EdgeInsets.zero,
      icon: const GuildRoundButton(icon: Icons.more_horiz_rounded),
      onSelected: (action) {
        switch (action) {
          case GuildMenuAction.edit:
            onEdit?.call();
          case GuildMenuAction.leave:
            confirmGuildAction(
              context,
              title: 'Leave guild?',
              message: 'You will stop contributing to this guild raid.',
              actionLabel: 'Leave',
              onConfirm: onLeave,
            );
          case GuildMenuAction.delete:
            confirmGuildAction(
              context,
              title: 'Delete guild?',
              message:
                  'This removes the guild, members, active raids, and contribution history.',
              actionLabel: 'Delete',
              onConfirm: onDelete,
            );
        }
      },
      itemBuilder: (_) => [
        if (guild.isLeader && onEdit != null)
          const PopupMenuItem(
            value: GuildMenuAction.edit,
            child: GuildMenuItem(
              icon: Icons.edit_rounded,
              label: 'Edit Guild',
              color: AppColors.blue,
            ),
          ),
        if (guild.isLeader)
          const PopupMenuItem(
            value: GuildMenuAction.delete,
            child: GuildMenuItem(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Guild',
              color: AppColors.red,
            ),
          )
        else
          const PopupMenuItem(
            value: GuildMenuAction.leave,
            child: GuildMenuItem(
              icon: Icons.logout_rounded,
              label: 'Leave Guild',
              color: AppColors.red,
            ),
          ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final GuildDetail guild;
  final VoidCallback onBack;
  final Widget menu;

  const _Hero({required this.guild, required this.onBack, required this.menu});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 362,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppIcons.guildHallHero,
              fit: BoxFit.cover,
              alignment: const Alignment(.7, -.2),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC040810), Color(0x00040810)],
                  stops: [0, .28],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xE6040810),
                    Color(0x99040810),
                    Color(0x00040810)
                  ],
                  stops: [0, .34, .64],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.backgroundAlt, Color(0x00080e14)],
                  stops: [0, .4],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GuildTopBar(
              title: 'Guild',
              subtitle: 'Train together. Go further.',
              onBack: onBack,
              trailing: menu,
            ),
          ),
          Positioned(
            left: 16,
            top: 72,
            child: SizedBox(
              width: 112,
              height: 158,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                      top: 0, left: 0, child: GuildRod(width: 112)),
                  Positioned(
                    top: 6,
                    left: 12,
                    child:
                        GuildCrest(icon: guild.icon, width: 88, aspect: 1.62),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guild.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guild.description.isEmpty ? 'Open guild' : guild.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFFb8c4d6), fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    GuildPill(
                        '${guild.memberCount}/${guild.maxMembers} members',
                        const Color(0xFFcbd5e4),
                        icon: Icons.groups_rounded),
                    guild.isOpen
                        ? const GuildPill('Open', AppColors.green,
                            icon: Icons.lock_open_rounded)
                        : const GuildPill(
                            'Invite only', AppColors.textSecondary,
                            icon: Icons.lock_rounded),
                    GuildPill(guildRoleLabel(guild.viewerRole),
                        guildRoleColor(guild.viewerRole)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hot;
  final bool badge;

  const _HubTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hot = false,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: hot
                    ? const [Color(0xFF2a2312), Color(0xFF15120a)]
                    : const [Color(0xFF0f1a2d), kGuildPanelBottom],
              ),
              border:
                  Border.all(color: hot ? const Color(0xCCf5b53f) : kGuildLine),
              borderRadius: radius,
              boxShadow: hot
                  ? const [BoxShadow(color: Color(0x33f5b53f), blurRadius: 14)]
                  : null,
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 22,
                        color: hot ? kGuildGoldLight : const Color(0xFFcfe0ff)),
                    const SizedBox(height: 7),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFcbd5e4),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: -5,
            right: -3,
            child: Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundAlt, width: 2),
              ),
              child: const Text('!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1)),
            ),
          ),
      ],
    );
  }
}

class _RaidCard extends StatelessWidget {
  final GuildRaid raid;
  final VoidCallback onOpen;
  const _RaidCard({required this.raid, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GuildCard(
      borderColor: const Color(0xFF2b5fb0),
      gradient: const [Color(0xFF0f1d36), Color(0xFF0a1220)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GuildBossFrame(icon: raid.bossIcon, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GuildLabel('Current raid'),
                    const SizedBox(height: 3),
                    Text(
                      raid.bossName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          raid.isDefeated
                              ? 'Defeated'
                              : 'Ends in ${guildTimeLeft(raid.timeRemaining)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GuildHpBar(percent: raid.hpPercent),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${guildNum(raid.totalDamage)} / ${guildNum(raid.maxHp)} HP',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${(raid.hpPercent * 100).round()}%',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GuildButton(
            label: 'View raid',
            icon: Icons.chevron_right_rounded,
            onTap: onOpen,
            compact: true,
            expand: false,
          ),
        ],
      ),
    );
  }
}

class _NoRaidCard extends StatelessWidget {
  final VoidCallback? onStartRaid;
  final VoidCallback onHistory;
  const _NoRaidCard({required this.onStartRaid, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return GuildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.orange),
              SizedBox(width: 8),
              Text('No active raid',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a shared HP boss fight and every member workout will damage it.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 14),
          if (onStartRaid != null) ...[
            GuildButton(
              label: 'Choose boss',
              icon: Icons.sports_martial_arts_rounded,
              onTap: onStartRaid,
              style: GuildButtonStyle.gold,
            ),
            const SizedBox(height: 8),
          ],
          GuildButton(
            label: 'Raid history',
            icon: Icons.history_rounded,
            onTap: onHistory,
            style: GuildButtonStyle.ghost,
          ),
        ],
      ),
    );
  }
}
