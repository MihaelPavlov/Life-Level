import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../models/guild_models.dart';
import '../widgets/guild_widgets.dart';

/// One guild member. [compact] is the Guild Hall preview row; the full card
/// adds a damage bar and the leader/officer management actions.
class GuildMemberCard extends StatelessWidget {
  final GuildMember member;
  final int maxDamage;
  final bool compact;
  final bool canKick;
  final bool canChangeRole;
  final VoidCallback? onKick;
  final ValueChanged<String>? onRoleChanged;

  const GuildMemberCard({
    super.key,
    required this.member,
    required this.maxDamage,
    this.compact = false,
    this.canKick = false,
    this.canChangeRole = false,
    this.onKick,
    this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = guildRoleColor(member.role);
    final ratio = maxDamage <= 0 ? 0.0 : member.raidDamage / maxDamage;
    return GuildCard(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 9 : 12),
      child: Row(
        children: [
          GuildAvatar(
              emoji: member.avatarEmoji,
              name: member.username,
              leader: member.isLeader),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _RoleTag(guildRoleLabel(member.role), roleColor),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${guildNum(member.raidDamage)} raid dmg',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11.5),
                ),
                if (!compact) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0).toDouble(),
                      minHeight: 6,
                      backgroundColor: const Color(0xFF070d18),
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canChangeRole)
            PopupMenuButton<String>(
              popUpAnimationStyle: AppMotion.animationStyle(
                context,
                enter: AppMotionTokens.micro,
                exit: AppMotionTokens.pressUp,
              ),
              tooltip: 'Change role',
              color: AppColors.surfaceElevated,
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
              iconColor: AppColors.blue,
              onSelected: onRoleChanged,
              itemBuilder: (_) => [
                if (!member.isOfficer)
                  const PopupMenuItem(
                    value: 'Officer',
                    child: GuildMenuItem(
                      icon: Icons.military_tech_rounded,
                      label: 'Make Officer',
                      color: AppColors.blue,
                    ),
                  ),
                if (member.isOfficer)
                  const PopupMenuItem(
                    value: 'Member',
                    child: GuildMenuItem(
                      icon: Icons.person_rounded,
                      label: 'Make Member',
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          if (canKick)
            IconButton(
              tooltip: 'Remove member',
              onPressed: onKick,
              icon: const Icon(Icons.person_remove_rounded, size: 19),
              color: AppColors.red,
            ),
        ],
      ),
    );
  }
}

class _RoleTag extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class GuildMembersView extends StatelessWidget {
  final GuildDetail guild;
  final VoidCallback onBack;
  final ValueChanged<String> onKick;
  final void Function(String userId, String role) onRoleChanged;

  const GuildMembersView({
    super.key,
    required this.guild,
    required this.onBack,
    required this.onKick,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxDamage = guild.members
        .fold<int>(0, (best, m) => m.raidDamage > best ? m.raidDamage : best);
    final openSeats = (guild.maxMembers - guild.members.length).clamp(0, 10);
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        GuildTopBar(
          title: 'Members',
          subtitle: '${guild.memberCount} of ${guild.maxMembers} seats filled',
          onBack: onBack,
          trailing: GuildPill(
              '${guild.memberCount}/${guild.maxMembers}', kGuildGold,
              icon: Icons.groups_rounded),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final member in guild.members)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GuildMemberCard(
                    member: member,
                    maxDamage: maxDamage,
                    canKick: guild.canManageMembers &&
                        !member.isLeader &&
                        (guild.isLeader || !member.isOfficer),
                    canChangeRole: guild.isLeader && !member.isLeader,
                    onKick: () => confirmGuildAction(
                      context,
                      title: 'Remove ${member.username}?',
                      message:
                          'This member will be removed from the guild and will stop contributing to active raids.',
                      actionLabel: 'Remove',
                      onConfirm: () => onKick(member.userId),
                    ),
                    onRoleChanged: (role) => onRoleChanged(member.userId, role),
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
              const GuildSectionHeader('What each role can do'),
              const _PermissionTable(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionTable extends StatelessWidget {
  const _PermissionTable();

  @override
  Widget build(BuildContext context) {
    Widget head(String t) => Center(
          child: Text(
            t.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .6),
          ),
        );
    Widget mark(bool on) => Center(
          child: on
              ? Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 12, color: AppColors.green),
                )
              : Container(
                  width: 6,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF33445f),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
        );
    TableRow row(
            String role, Color color, bool raid, bool members, bool edit) =>
        TableRow(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(role,
                style: TextStyle(
                    color: color, fontSize: 12.5, fontWeight: FontWeight.w800)),
          ),
          mark(raid),
          mark(members),
          mark(edit),
        ]);
    return GuildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                const SizedBox(),
                head('Raids'),
                head('Members'),
                head('Edit'),
              ]),
              row('Leader', kGuildGold, true, true, true),
              row('Officer', AppColors.blue, true, true, false),
              row('Member', AppColors.textSecondary, false, false, false),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1a2840), height: 1),
          const SizedBox(height: 10),
          const Text(
            'Officers can only remove regular members. Only the leader changes roles or edits the guild.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
