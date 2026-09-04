import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../boss/widgets/boss_icon.dart';
import '../models/guild_models.dart';
import '../providers/guild_provider.dart';

class GuildScreen extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const GuildScreen({super.key, this.onClose});

  @override
  ConsumerState<GuildScreen> createState() => _GuildScreenState();
}

class _GuildScreenState extends ConsumerState<GuildScreen> {
  String _mode = 'home';
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _editNameCtrl = TextEditingController();
  final _editDescCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _icon = 'shield';
  String _editIcon = 'shield';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _editNameCtrl.dispose();
    _editDescCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = ref.read(guildServiceProvider).messageFor(error);
    AppToast.error(context, message);
  }

  Future<void> _create() async {
    await ref.read(guildProvider.notifier).create(
          _nameCtrl.text,
          _descCtrl.text,
          _icon,
        );
    final state = ref.read(guildProvider);
    state.whenOrNull(
      data: (_) => setState(() => _mode = 'home'),
      error: (e, _) => _showError(e),
    );
  }

  void _startEdit(GuildDetail guild) {
    _editNameCtrl.text = guild.name;
    _editDescCtrl.text = guild.description;
    _editIcon = guild.icon;
    setState(() => _mode = 'edit');
  }

  Future<void> _saveEdit() async {
    await ref.read(guildProvider.notifier).updateGuild(
          _editNameCtrl.text,
          _editDescCtrl.text,
          _editIcon,
        );
    final state = ref.read(guildProvider);
    state.whenOrNull(
      data: (_) => setState(() => _mode = 'home'),
      error: (e, _) => _showError(e),
    );
  }

  Future<void> _join(String guildId) async {
    await ref.read(guildProvider.notifier).join(guildId);
    final state = ref.read(guildProvider);
    state.whenOrNull(
      data: (_) => setState(() => _mode = 'home'),
      error: (e, _) => _showError(e),
    );
  }

  Future<void> _startRaid(String bossId) async {
    await ref.read(guildProvider.notifier).startRaid(bossId);
    final state = ref.read(guildProvider);
    state.whenOrNull(
      data: (_) => setState(() => _mode = 'home'),
      error: (e, _) => _showError(e),
    );
  }

  Future<void> _setRole(String guildId, String userId, String role) async {
    await ref.read(guildProvider.notifier).updateMemberRole(guildId, userId, role);
    final state = ref.read(guildProvider);
    state.whenOrNull(error: (e, _) => _showError(e));
  }

  @override
  Widget build(BuildContext context) {
    final guildAsync = ref.watch(guildProvider);

    return Material(
      color: AppColors.backgroundAlt,
      child: SafeArea(
        child: guildAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          ),
          error: (error, _) => _ErrorView(
            message: ref.read(guildServiceProvider).messageFor(error),
            onRetry: () => ref.read(guildProvider.notifier).refresh(),
          ),
          data: (guild) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  title: guild == null ? 'Guild' : guild.name,
                  onClose: widget.onClose,
                  guild: guild,
                  onLeave: () => ref.read(guildProvider.notifier).leave(),
                  onDelete: () => ref.read(guildProvider.notifier).delete(),
                  onEdit: guild == null ? null : () => _startEdit(guild),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _buildBody(guild),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(GuildDetail? guild) {
    if (guild == null) {
      return switch (_mode) {
        'create' => _CreateGuildView(
            key: const ValueKey('create'),
            nameCtrl: _nameCtrl,
            descCtrl: _descCtrl,
            icon: _icon,
            onIconChanged: (v) => setState(() => _icon = v),
            onBack: () => setState(() => _mode = 'home'),
            onCreate: _create,
          ),
        'search' => _SearchGuildView(
            key: const ValueKey('search'),
            controller: _searchCtrl,
            onBack: () => setState(() => _mode = 'home'),
            onJoin: _join,
          ),
        _ => _NoGuildView(
            key: const ValueKey('none'),
            onCreate: () => setState(() => _mode = 'create'),
            onSearch: () => setState(() => _mode = 'search'),
          ),
      };
    }

    if (_mode == 'startRaid') {
      return _StartRaidView(
        key: const ValueKey('startRaid'),
        onBack: () => setState(() => _mode = 'home'),
        onStart: _startRaid,
      );
    }

    if (_mode == 'edit') {
      return _CreateGuildView(
        key: const ValueKey('edit'),
        title: 'Edit Guild',
        actionLabel: 'Save Changes',
        actionIcon: Icons.save_rounded,
        nameCtrl: _editNameCtrl,
        descCtrl: _editDescCtrl,
        icon: _editIcon,
        onIconChanged: (v) => setState(() => _editIcon = v),
        onBack: () => setState(() => _mode = 'home'),
        onCreate: _saveEdit,
      );
    }

    if (_mode == 'history') {
      return _RaidHistoryView(
        key: const ValueKey('history'),
        onBack: () => setState(() => _mode = 'home'),
      );
    }

    return _GuildHomeView(
      key: ValueKey(guild.activeRaid?.id ?? guild.id),
      guild: guild,
      onStartRaid: guild.canManageRaid ? () => setState(() => _mode = 'startRaid') : null,
      onHistory: () => setState(() => _mode = 'history'),
      onKick: (userId) => ref.read(guildProvider.notifier).kick(guild.id, userId),
      onRoleChanged: (userId, role) => _setRole(guild.id, userId, role),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  final GuildDetail? guild;
  final VoidCallback onLeave;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const _Header({
    required this.title,
    required this.onClose,
    required this.guild,
    required this.onLeave,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currentGuild = guild;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
      child: Row(
        children: [
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
            ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: .14),
              border: Border.all(color: AppColors.purple.withValues(alpha: .45)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Guild raids',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (currentGuild != null)
            PopupMenuButton<_GuildMenuAction>(
              tooltip: 'Guild actions',
              color: AppColors.surfaceElevated,
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              onSelected: (action) {
                switch (action) {
                  case _GuildMenuAction.edit:
                    onEdit?.call();
                  case _GuildMenuAction.leave:
                    _confirmGuildAction(
                      context,
                      title: 'Leave guild?',
                      message: 'You will stop contributing to this guild raid.',
                      actionLabel: 'Leave',
                      onConfirm: onLeave,
                    );
                  case _GuildMenuAction.delete:
                    _confirmGuildAction(
                      context,
                      title: 'Delete guild?',
                      message: 'This removes the guild, members, active raids, and contribution history.',
                      actionLabel: 'Delete',
                      onConfirm: onDelete,
                    );
                }
              },
              itemBuilder: (_) => [
                if (currentGuild.isLeader)
                  const PopupMenuItem(
                    value: _GuildMenuAction.edit,
                    child: _GuildMenuItem(
                      icon: Icons.edit_rounded,
                      label: 'Edit Guild',
                      color: AppColors.purple,
                    ),
                  ),
                if (currentGuild.isLeader)
                  const PopupMenuItem(
                    value: _GuildMenuAction.delete,
                    child: _GuildMenuItem(
                      icon: Icons.delete_forever_rounded,
                      label: 'Delete Guild',
                      color: AppColors.red,
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: _GuildMenuAction.leave,
                    child: _GuildMenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Leave Guild',
                      color: AppColors.red,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

enum _GuildMenuAction { edit, leave, delete }

class _GuildMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _GuildMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

void _confirmGuildAction(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required VoidCallback onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child: Text(actionLabel, style: const TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
}

class _NoGuildView extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onSearch;

  const _NoGuildView({
    super.key,
    required this.onCreate,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        const _HeroPanel(
          icon: Icons.shield_rounded,
          title: 'No Guild',
          subtitle: 'Create a crew or join one to turn logged workouts into shared raid damage.',
        ),
        const SizedBox(height: 14),
        _ActionButton(
          label: 'Create Guild',
          icon: Icons.add_rounded,
          color: AppColors.purple,
          onTap: onCreate,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Find Guilds',
          icon: Icons.search_rounded,
          color: AppColors.blue,
          onTap: onSearch,
        ),
        const SizedBox(height: 18),
        const _InfoStrip(
          icon: Icons.groups_rounded,
          label: 'Max 5 members',
          value: 'Leader starts one active raid at a time.',
        ),
      ],
    );
  }
}

class _CreateGuildView extends StatelessWidget {
  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String icon;
  final ValueChanged<String> onIconChanged;
  final VoidCallback onBack;
  final VoidCallback onCreate;

  const _CreateGuildView({
    super.key,
    this.title = 'Create Guild',
    this.actionLabel = 'Create Guild',
    this.actionIcon = Icons.shield_rounded,
    required this.nameCtrl,
    required this.descCtrl,
    required this.icon,
    required this.onIconChanged,
    required this.onBack,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      children: [
        _BackTitle(title: title, onBack: onBack),
        const SizedBox(height: 12),
        _Field(controller: nameCtrl, label: 'Name', hint: 'Iron Wolves'),
        const SizedBox(height: 12),
        _Field(controller: descCtrl, label: 'Description', hint: 'Morning runs. Weekend raids.', maxLines: 3),
        const SizedBox(height: 14),
        const _SectionLabel('Banner'),
        Row(
          children: [
            for (final item in const ['shield', 'wolf', 'flame', 'crown'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _IconChoice(
                    id: item,
                    selected: icon == item,
                    onTap: () => onIconChanged(item),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _ActionButton(
          label: actionLabel,
          icon: actionIcon,
          color: AppColors.purple,
          onTap: onCreate,
        ),
      ],
    );
  }
}

class _SearchGuildView extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onJoin;

  const _SearchGuildView({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onJoin,
  });

  @override
  ConsumerState<_SearchGuildView> createState() => _SearchGuildViewState();
}

class _SearchGuildViewState extends ConsumerState<_SearchGuildView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(guildSearchProvider(_query));
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      children: [
        _BackTitle(title: 'Search Guilds', onBack: widget.onBack),
        const SizedBox(height: 12),
        TextField(
          controller: widget.controller,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _inputDecoration('Search guilds').copyWith(
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 14),
        results.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          ),
          error: (error, _) => _InfoStrip(
            icon: Icons.error_outline_rounded,
            label: 'Search failed',
            value: error.toString(),
          ),
          data: (guilds) => Column(
            children: [
              for (final guild in guilds)
                _GuildSearchCard(guild: guild, onJoin: () => widget.onJoin(guild.id)),
              if (guilds.isEmpty)
                const _InfoStrip(
                  icon: Icons.search_off_rounded,
                  label: 'No guilds found',
                  value: 'Try another name or create your own.',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuildHomeView extends StatelessWidget {
  final GuildDetail guild;
  final VoidCallback? onStartRaid;
  final VoidCallback onHistory;
  final ValueChanged<String> onKick;
  final void Function(String userId, String role) onRoleChanged;

  const _GuildHomeView({
    super.key,
    required this.guild,
    required this.onStartRaid,
    required this.onHistory,
    required this.onKick,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: () async {
        final container = ProviderScope.containerOf(context, listen: false);
        await container.read(guildProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          _GuildBanner(guild: guild),
          const SizedBox(height: 14),
          if (guild.activeRaid == null)
            _NoRaidPanel(onStartRaid: onStartRaid, onHistory: onHistory)
          else
            _ActiveRaidPanel(raid: guild.activeRaid!),
          if (guild.activeRaid != null) ...[
            const SizedBox(height: 10),
            _ActionButton(
              label: 'Raid History',
              icon: Icons.history_rounded,
              color: AppColors.purple,
              outlined: true,
              onTap: onHistory,
            ),
          ],
          const SizedBox(height: 18),
          const _SectionLabel('Members'),
          for (final member in guild.members)
            _MemberRow(
              member: member,
              canKick: guild.canManageMembers &&
                  !member.isLeader &&
                  (guild.isLeader || !member.isOfficer),
              canChangeRole: guild.isLeader && !member.isLeader,
              onKick: () => _confirmGuildAction(
                context,
                title: 'Remove ${member.username}?',
                message: 'This member will be removed from the guild and will stop contributing to active raids.',
                actionLabel: 'Remove',
                onConfirm: () => onKick(member.userId),
              ),
              onRoleChanged: (role) => onRoleChanged(member.userId, role),
            ),
        ],
      ),
    );
  }
}

class _StartRaidView extends ConsumerWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onStart;

  const _StartRaidView({
    super.key,
    required this.onBack,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosses = ref.watch(guildRaidBossesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      children: [
        _BackTitle(title: 'Start Raid', onBack: onBack),
        const SizedBox(height: 12),
        bosses.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: AppColors.red),
            ),
          ),
          error: (error, _) => _InfoStrip(
            icon: Icons.error_outline_rounded,
            label: 'Bosses unavailable',
            value: error.toString(),
          ),
          data: (items) => Column(
            children: [
              for (final boss in items)
                _RaidBossCard(boss: boss, onStart: () => onStart(boss.id)),
              if (items.isEmpty)
                const _InfoStrip(
                  icon: Icons.warning_rounded,
                  label: 'No raid bosses',
                  value: 'Unlock bosses on the map first.',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RaidHistoryView extends ConsumerWidget {
  final VoidCallback onBack;

  const _RaidHistoryView({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(guildRaidHistoryProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      children: [
        _BackTitle(title: 'Raid History', onBack: onBack),
        const SizedBox(height: 12),
        history.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(color: AppColors.purple),
            ),
          ),
          error: (error, _) => _InfoStrip(
            icon: Icons.error_outline_rounded,
            label: 'History unavailable',
            value: ref.read(guildServiceProvider).messageFor(error),
          ),
          data: (raids) => Column(
            children: [
              for (final raid in raids) _RaidHistoryCard(raid: raid),
              if (raids.isEmpty)
                const _InfoStrip(
                  icon: Icons.history_rounded,
                  label: 'No completed raids',
                  value: 'Defeated and expired raids will appear here.',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuildBanner extends StatelessWidget {
  final GuildDetail guild;
  const _GuildBanner({required this.guild});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          _GuildIcon(icon: guild.icon, size: 62),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guild.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guild.description.isEmpty ? 'Open guild' : guild.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Pill('${guild.memberCount}/${guild.maxMembers}', AppColors.purple),
                    const SizedBox(width: 8),
                    _Pill(_roleLabel(guild.viewerRole), _roleColor(guild.viewerRole)),
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

class _NoRaidPanel extends StatelessWidget {
  final VoidCallback? onStartRaid;
  final VoidCallback onHistory;
  const _NoRaidPanel({required this.onStartRaid, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: AppColors.orange),
              SizedBox(width: 8),
              Text(
                'No Active Raid',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a shared HP boss fight and every member workout will damage it.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.45),
          ),
          if (onStartRaid != null) ...[
            const SizedBox(height: 14),
            _ActionButton(
              label: 'Choose Boss',
              icon: Icons.sports_martial_arts_rounded,
              color: AppColors.red,
              onTap: onStartRaid!,
            ),
          ],
          const SizedBox(height: 10),
          _ActionButton(
            label: 'Raid History',
            icon: Icons.history_rounded,
            color: AppColors.purple,
            outlined: true,
            onTap: onHistory,
          ),
        ],
      ),
    );
  }
}

class _RaidHistoryCard extends StatelessWidget {
  final GuildRaid raid;

  const _RaidHistoryCard({required this.raid});

  @override
  Widget build(BuildContext context) {
    final statusColor = raid.isDefeated ? AppColors.green : AppColors.textMuted;
    final statusIcon = raid.isDefeated
        ? Icons.verified_rounded
        : Icons.hourglass_disabled_rounded;
    final statusLabel = raid.isDefeated ? 'Defeated' : 'Expired';
    final endedAt = raid.isDefeated ? raid.defeatedAt : raid.expiresAt;
    final rewardLabel = raid.isDefeated
        ? (raid.rewardClaimed ? '+${raid.rewardXp} XP claimed' : '+${raid.rewardXp} XP pending')
        : 'No reward';
    final rewardColor = raid.isDefeated
        ? (raid.rewardClaimed ? AppColors.green : AppColors.orange)
        : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
        borderColor: statusColor.withValues(alpha: .38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _BossIcon(icon: raid.bossIcon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        raid.bossName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(rewardLabel, rewardColor),
              ],
            ),
            const SizedBox(height: 14),
            _HpBar(percent: raid.hpPercent),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${raid.totalDamage}/${raid.maxHp} DMG',
                  style: TextStyle(
                    color: raid.isDefeated ? AppColors.green : AppColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  raid.isDefeated ? 'Cleared' : '${raid.remainingHp} HP missed',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _HistoryMetric(
                  label: raid.isDefeated ? 'Ended' : 'Expired',
                  value: _compactDateTime(endedAt),
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                _HistoryMetric(
                  label: 'Reward',
                  value: raid.isDefeated
                      ? (raid.rewardClaimed ? 'Claimed' : 'Pending')
                      : 'None',
                  color: raid.isDefeated ? AppColors.green : AppColors.red,
                ),
                const SizedBox(width: 8),
                _HistoryMetric(
                  label: 'MVP',
                  value: raid.mvpUsername == null ? '-' : raid.mvpUsername!,
                  color: AppColors.purple,
                ),
              ],
            ),
            if (raid.isDefeated && raid.mvpUsername != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .09),
                  border: Border.all(color: AppColors.purple.withValues(alpha: .24)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: AppColors.orange, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${raid.mvpUsername} dealt ${raid.mvpDamage} damage and received +${raid.mvpBonusXp} XP.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (raid.contributions.isNotEmpty) ...[
              const SizedBox(height: 14),
              const _SectionLabel('Contribution Ranking'),
              for (final c in raid.contributions.take(5))
                _ContributionRow(
                  contribution: c,
                  maxDamage: raid.contributions.first.damageDealt,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HistoryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          border: Border.all(color: color.withValues(alpha: .24)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _compactDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

class _ActiveRaidPanel extends StatelessWidget {
  final GuildRaid raid;
  const _ActiveRaidPanel({required this.raid});

  @override
  Widget build(BuildContext context) {
    final remaining = raid.timeRemaining;
    return _Card(
      borderColor: AppColors.red.withValues(alpha: .45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BossIcon(icon: raid.bossIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Raid',
                      style: TextStyle(color: AppColors.red, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      raid.bossName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${remaining.inDays}d ${remaining.inHours % 24}h left',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _HpBar(percent: raid.hpPercent),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${raid.totalDamage}/${raid.maxHp} DMG',
                style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${raid.remainingHp} HP left',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Pill('${raid.guildSizeAtStart} members', AppColors.purple),
              _Pill('+${raid.rewardXp} XP', AppColors.orange),
              if (raid.maxHp != raid.baseMaxHp)
                _Pill('Base ${raid.baseMaxHp} HP', AppColors.textMuted),
            ],
          ),
          if (raid.contributions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel('Damage'),
            for (final c in raid.contributions.take(5))
              _ContributionRow(contribution: c, maxDamage: raid.contributions.first.damageDealt),
          ],
        ],
      ),
    );
  }
}

class _GuildSearchCard extends StatelessWidget {
  final GuildSearchItem guild;
  final VoidCallback onJoin;

  const _GuildSearchCard({required this.guild, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
        child: Row(
          children: [
            _GuildIcon(icon: guild.icon, size: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guild.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    guild.description.isEmpty ? 'Open guild' : guild.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _Pill('${guild.memberCount}/${guild.maxMembers}', AppColors.purple),
                ],
              ),
            ),
            IconButton(
              onPressed: guild.memberCount >= guild.maxMembers ? null : onJoin,
              icon: const Icon(Icons.login_rounded),
              color: AppColors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _RaidBossCard extends StatelessWidget {
  final GuildRaidBoss boss;
  final VoidCallback onStart;

  const _RaidBossCard({required this.boss, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
        child: Row(
          children: [
            _BossIcon(icon: boss.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boss.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Pill('${boss.maxHp} HP', AppColors.red),
                      _Pill('+${boss.rewardXp} XP', AppColors.orange),
                      if (boss.isMini) _Pill('Mini', AppColors.purple),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              color: AppColors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final GuildMember member;
  final bool canKick;
  final bool canChangeRole;
  final VoidCallback onKick;
  final ValueChanged<String> onRoleChanged;

  const _MemberRow({
    required this.member,
    required this.canKick,
    required this.canChangeRole,
    required this.onKick,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Card(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceElevated,
              child: Text(member.avatarEmoji.isEmpty ? '?' : member.avatarEmoji),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                  ),
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _TinyPill(
                        _roleLabel(member.role),
                        _roleColor(member.role),
                      ),
                      Text(
                        '${member.raidDamage} raid dmg',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canChangeRole)
              PopupMenuButton<String>(
                tooltip: 'Change role',
                color: AppColors.surfaceElevated,
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 19),
                iconColor: AppColors.purple,
                onSelected: onRoleChanged,
                itemBuilder: (_) => [
                  if (!member.isOfficer)
                    const PopupMenuItem(
                      value: 'Officer',
                      child: _GuildMenuItem(
                        icon: Icons.military_tech_rounded,
                        label: 'Make Officer',
                        color: AppColors.purple,
                      ),
                    ),
                  if (member.isOfficer)
                    const PopupMenuItem(
                      value: 'Member',
                      child: _GuildMenuItem(
                        icon: Icons.person_rounded,
                        label: 'Make Member',
                        color: AppColors.blue,
                      ),
                    ),
                ],
              ),
            if (canKick)
              IconButton(
                onPressed: onKick,
                icon: const Icon(Icons.person_remove_rounded, size: 18),
                color: AppColors.red,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  final GuildRaidContribution contribution;
  final int maxDamage;

  const _ContributionRow({required this.contribution, required this.maxDamage});

  @override
  Widget build(BuildContext context) {
    final percent = maxDamage <= 0 ? 0.0 : contribution.damageDealt / maxDamage;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${contribution.rank}',
              style: TextStyle(
                color: contribution.isMvp ? AppColors.orange : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 104,
            child: Row(
              children: [
                if (contribution.isMvp) ...[
                  const Icon(Icons.emoji_events_rounded, color: AppColors.orange, size: 13),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(
                    contribution.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _MiniBar(percent: percent)),
          const SizedBox(width: 8),
          Text(
            '${contribution.damageDealt}',
            style: const TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.purple.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.purple, size: 54),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: borderColor ?? AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          border: Border.all(color: color.withValues(alpha: .75)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: outlined ? color : Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: outlined ? color : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoStrip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackTitle extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _BackTitle({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
        ),
        Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(hint).copyWith(labelText: label),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.purple),
      ),
    );

class _IconChoice extends StatelessWidget {
  final String id;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: selected ? AppColors.purple.withValues(alpha: .18) : AppColors.surface,
          border: Border.all(color: selected ? AppColors.purple : AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: _GuildIcon(icon: id, size: 34)),
      ),
    );
  }
}

class _GuildIcon extends StatelessWidget {
  final String icon;
  final double size;

  const _GuildIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    final data = switch (icon) {
      'wolf' => Icons.pets_rounded,
      'flame' => Icons.local_fire_department_rounded,
      'crown' => Icons.workspace_premium_rounded,
      _ => Icons.shield_rounded,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: .14),
        border: Border.all(color: AppColors.purple.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Icon(data, color: AppColors.purple, size: size * .56),
    );
  }
}

class _BossIcon extends StatelessWidget {
  final String icon;
  const _BossIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: .12),
        border: Border.all(color: AppColors.red.withValues(alpha: .42)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: BossIcon(
          icon: icon.isEmpty ? '?' : icon,
          size: 46,
          emojiSize: 27,
          visualScale: icon.startsWith('assets/') ? 1.2 : 1,
        ),
      ),
    );
  }
}

class _HpBar extends StatelessWidget {
  final double percent;
  const _HpBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 12,
        color: AppColors.surfaceElevated,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: percent.clamp(0.0, 1.0).toDouble(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.red, AppColors.redDark]),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double percent;
  const _MiniBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 7,
        color: AppColors.surfaceElevated,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: percent.clamp(0.0, 1.0).toDouble(),
          child: Container(color: AppColors.purple),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TinyPill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .32)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }
}

String _roleLabel(String role) {
  final normalized = role.toLowerCase();
  if (normalized == 'leader') return 'Leader';
  if (normalized == 'officer') return 'Officer';
  return 'Member';
}

Color _roleColor(String role) {
  final normalized = role.toLowerCase();
  if (normalized == 'leader') return AppColors.orange;
  if (normalized == 'officer') return AppColors.purple;
  return AppColors.blue;
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Guild unavailable',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 18),
            _ActionButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              color: AppColors.purple,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
