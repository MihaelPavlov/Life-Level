import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/guild_models.dart';
import '../providers/guild_provider.dart';
import '../widgets/guild_widgets.dart';
import 'guild_find_views.dart';
import 'guild_home_view.dart';
import 'guild_members_view.dart';
import 'guild_raid_view.dart';

/// Guild feature root. Owns the form state and which sub-screen is showing
/// (`home`, `raid`, `members`, `startRaid`, `history`, `edit`, `create`,
/// `search`); each sub-screen lives in its own file.
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

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _go(String mode) => setState(() => _mode = mode);

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
      data: (_) => _go('home'),
      error: (e, _) => _showError(e),
    );
  }

  void _startEdit(GuildDetail guild) {
    _editNameCtrl.text = guild.name;
    _editDescCtrl.text = guild.description;
    _editIcon = guild.icon;
    _go('edit');
  }

  Future<void> _saveEdit() async {
    await ref.read(guildProvider.notifier).updateGuild(
          _editNameCtrl.text,
          _editDescCtrl.text,
          _editIcon,
        );
    final state = ref.read(guildProvider);
    state.whenOrNull(
      data: (_) => _go('home'),
      error: (e, _) => _showError(e),
    );
  }

  Future<void> _join(String guildId) async {
    await ref.read(guildProvider.notifier).join(guildId);
    final state = ref.read(guildProvider);
    state.whenOrNull(
      data: (_) => _go('home'),
      error: (e, _) => _showError(e),
    );
  }

  Future<void> _startRaid(String bossId) async {
    await ref.read(guildProvider.notifier).startRaid(bossId);
    final state = ref.read(guildProvider);
    state.whenOrNull(
      data: (_) => _go('raid'),
      error: (e, _) => _showError(e),
    );
  }

  Future<void> _setRole(String guildId, String userId, String role) async {
    await ref
        .read(guildProvider.notifier)
        .updateMemberRole(guildId, userId, role);
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
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
          error: (error, _) => GuildErrorView(
            message: ref.read(guildServiceProvider).messageFor(error),
            onRetry: () => ref.read(guildProvider.notifier).refresh(),
          ),
          data: (guild) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _buildBody(guild),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(GuildDetail? guild) {
    if (guild == null) {
      return switch (_mode) {
        'create' => GuildFormView(
            key: const ValueKey('create'),
            title: 'Create Guild',
            subtitle: 'Design your banner and found your crew',
            actionLabel: 'Found guild',
            nameCtrl: _nameCtrl,
            descCtrl: _descCtrl,
            icon: _icon,
            onIconChanged: (v) => setState(() => _icon = v),
            onBack: () => _go('home'),
            onSubmit: _create,
          ),
        'search' => GuildSearchView(
            key: const ValueKey('search'),
            controller: _searchCtrl,
            onBack: () => _go('home'),
            onCreate: () => _go('create'),
            onJoin: _join,
          ),
        _ => GuildNoGuildView(
            key: const ValueKey('none'),
            onBack: _close,
            onCreate: () => _go('create'),
            onSearch: () => _go('search'),
          ),
      };
    }

    final canStartRaid = guild.canManageRaid ? () => _go('startRaid') : null;

    return switch (_mode) {
      'startRaid' => GuildStartRaidView(
          key: const ValueKey('startRaid'),
          onBack: () => _go('home'),
          onStart: _startRaid,
        ),
      'edit' => GuildFormView(
          key: const ValueKey('edit'),
          title: 'Guild Settings',
          subtitle: 'Crest, name and motto',
          actionLabel: 'Save changes',
          nameCtrl: _editNameCtrl,
          descCtrl: _editDescCtrl,
          icon: _editIcon,
          onIconChanged: (v) => setState(() => _editIcon = v),
          onBack: () => _go('home'),
          onSubmit: _saveEdit,
        ),
      'history' => GuildRaidHistoryView(
          key: const ValueKey('history'),
          onBack: () => _go('home'),
        ),
      'raid' => GuildRaidView(
          key: ValueKey('raid-${guild.activeRaid?.id ?? 'none'}'),
          guild: guild,
          onBack: () => _go('home'),
          onHistory: () => _go('history'),
          onStartRaid: canStartRaid,
        ),
      'members' => GuildMembersView(
          key: const ValueKey('members'),
          guild: guild,
          onBack: () => _go('home'),
          onKick: (userId) =>
              ref.read(guildProvider.notifier).kick(guild.id, userId),
          onRoleChanged: (userId, role) => _setRole(guild.id, userId, role),
        ),
      _ => GuildHomeView(
          key: ValueKey('home-${guild.activeRaid?.id ?? guild.id}'),
          guild: guild,
          onBack: _close,
          onMembers: () => _go('members'),
          onRaid: () => _go('raid'),
          onHistory: () => _go('history'),
          onStartRaid: canStartRaid,
          onEdit: guild.canEditGuild ? () => _startEdit(guild) : null,
          onLeave: () => ref.read(guildProvider.notifier).leave(),
          onDelete: () => ref.read(guildProvider.notifier).delete(),
        ),
    };
  }
}
