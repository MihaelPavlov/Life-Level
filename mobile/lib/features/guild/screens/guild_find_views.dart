import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../models/guild_models.dart';
import '../providers/guild_provider.dart';
import '../widgets/guild_widgets.dart';

/// Landing state for players without a guild.
class GuildNoGuildView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onCreate;
  final VoidCallback onSearch;

  const GuildNoGuildView({
    super.key,
    required this.onBack,
    required this.onCreate,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  AppIcons.guildFindHero,
                  fit: BoxFit.cover,
                  alignment: const Alignment(.2, -.4),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [AppColors.backgroundAlt, Color(0x00080e14)],
                      stops: [0, .6],
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
                      colors: [Color(0xB3040810), Color(0x00040810)],
                      stops: [0, .7],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCC040810), Color(0x00040810)],
                      stops: [0, .3],
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
                ),
              ),
              const Positioned(
                left: 16,
                right: 16,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your crew is waiting',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                    SizedBox(height: 6),
                    Text(
                      'Join a guild or found your own to turn logged workouts into shared raid damage.',
                      style: TextStyle(
                          color: Color(0xFFb8c4d6), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            children: [
              GuildButton(
                label: 'Find a guild',
                icon: Icons.search_rounded,
                onTap: onSearch,
              ),
              const SizedBox(height: 10),
              GuildButton(
                label: 'Create a guild',
                icon: Icons.add_rounded,
                onTap: onCreate,
                style: GuildButtonStyle.gold,
              ),
              const SizedBox(height: 16),
              const GuildInfoStrip(
                icon: Icons.groups_rounded,
                label: 'Up to 5 members',
                value: 'A leader or officer starts one active raid at a time.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GuildSearchView extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onCreate;
  final ValueChanged<String> onJoin;

  const GuildSearchView({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  ConsumerState<GuildSearchView> createState() => _GuildSearchViewState();
}

class _GuildSearchViewState extends ConsumerState<GuildSearchView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(guildSearchProvider(_query));
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        GuildTopBar(
          title: 'Find a Guild',
          subtitle: 'Train with people who move like you',
          onBack: widget.onBack,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: widget.controller,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: guildInputDecoration('Search by name').copyWith(
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted),
                ),
              ),
              const GuildSectionHeader('Guilds'),
              results.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: AppColors.blue),
                  ),
                ),
                error: (error, _) => GuildInfoStrip(
                  icon: Icons.error_outline_rounded,
                  label: 'Search failed',
                  value: error.toString(),
                ),
                data: (guilds) => Column(
                  children: [
                    for (final guild in guilds)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GuildResultCard(
                          guild: guild,
                          onJoin: () => widget.onJoin(guild.id),
                        ),
                      ),
                    if (guilds.isEmpty)
                      const GuildInfoStrip(
                        icon: Icons.search_off_rounded,
                        label: 'No guilds found',
                        value: 'Try another name or create your own.',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GuildCard(
                borderColor: const Color(0x66f5b53f),
                gradient: const [Color(0xFF1c1809), Color(0xFF0e0c06)],
                child: Column(
                  children: [
                    const Text('Can’t find your crew?',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text(
                        'Found your own guild and invite up to 4 friends.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11.5)),
                    const SizedBox(height: 12),
                    GuildButton(
                      label: 'Create a guild',
                      onTap: widget.onCreate,
                      style: GuildButtonStyle.gold,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuildResultCard extends StatelessWidget {
  final GuildSearchItem guild;
  final VoidCallback onJoin;
  const _GuildResultCard({required this.guild, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final full = guild.memberCount >= guild.maxMembers;
    return GuildCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GuildCrest(icon: guild.icon, width: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guild.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  guild.description.isEmpty ? 'Open guild' : guild.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.35),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    GuildPill('${guild.memberCount}/${guild.maxMembers}',
                        const Color(0xFFcbd5e4),
                        icon: Icons.groups_rounded),
                    guild.isOpen
                        ? const GuildPill('Open', AppColors.green)
                        : const GuildPill(
                            'Invite only', AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GuildButton(
            label: full ? 'Full' : 'Join',
            onTap: full ? null : onJoin,
            compact: true,
            expand: false,
            style: full ? GuildButtonStyle.ghost : GuildButtonStyle.primary,
          ),
        ],
      ),
    );
  }
}

/// Create / edit form with a live crest preview.
class GuildFormView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String icon;
  final ValueChanged<String> onIconChanged;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const GuildFormView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.nameCtrl,
    required this.descCtrl,
    required this.icon,
    required this.onIconChanged,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        GuildTopBar(title: title, subtitle: subtitle, onBack: onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const GuildRod(width: 100),
                    Transform.translate(
                      offset: const Offset(0, -3),
                      child: GuildCrest(icon: icon, width: 80, aspect: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const GuildLabel('Crest'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final item in kGuildCrestIcons)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: item == kGuildCrestIcons.last ? 0 : 8),
                        child: _CrestChoice(
                          id: item,
                          selected: icon == item,
                          onTap: () => onIconChanged(item),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              GuildField(
                controller: nameCtrl,
                label: 'Guild name',
                hint: 'Iron Wolves',
                maxLength: 24,
              ),
              const SizedBox(height: 16),
              GuildField(
                controller: descCtrl,
                label: 'Motto',
                hint: 'Morning runs. Weekend raids.',
                maxLines: 3,
                maxLength: 90,
              ),
              const SizedBox(height: 20),
              GuildButton(label: actionLabel, onTap: onSubmit),
            ],
          ),
        ),
      ],
    );
  }
}

class _CrestChoice extends StatelessWidget {
  final String id;
  final bool selected;
  final VoidCallback onTap;
  const _CrestChoice(
      {required this.id, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2a2312), Color(0xFF15120a)],
                  )
                : null,
            color: selected ? null : kGuildInk,
            border: Border.all(color: selected ? kGuildGold : kGuildLineStrong),
            borderRadius: radius,
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x33f5b53f), blurRadius: 12)]
                : null,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(
              child: Icon(guildIconData(id),
                  size: 22,
                  color: selected ? kGuildGoldLight : const Color(0xFFcfe0ff)),
            ),
          ),
        ),
      ),
    );
  }
}
