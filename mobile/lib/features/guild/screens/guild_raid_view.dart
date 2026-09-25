import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../character/providers/character_provider.dart';
import '../models/guild_models.dart';
import '../providers/guild_provider.dart';
import '../widgets/guild_widgets.dart';
import 'guild_home_view.dart' show guildTimeLeft;
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/motion/reward_fx.dart';

/// Active raid detail: boss, shared HP, your damage, contributions, rewards.
class GuildRaidView extends ConsumerWidget {
  final GuildDetail guild;
  final VoidCallback onBack;
  final VoidCallback onHistory;
  final VoidCallback? onStartRaid;

  const GuildRaidView({
    super.key,
    required this.guild,
    required this.onBack,
    required this.onHistory,
    required this.onStartRaid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raid = guild.activeRaid;
    if (raid == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
        children: [
          GuildTopBar(
              title: 'Guild Raid',
              subtitle: 'One boss, one shared HP bar',
              onBack: onBack),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: GuildCard(
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
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.45),
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
            ),
          ),
        ],
      );
    }

    final me = ref.watch(characterProfileProvider).valueOrNull?.username;
    final ranked = [...raid.contributions]
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final mine = me == null
        ? null
        : ranked
            .cast<GuildRaidContribution?>()
            .firstWhere((c) => c?.username == me, orElse: () => null);
    final topDamage = ranked.isEmpty ? 0 : ranked.first.damageDealt;
    final timeLeft = guildTimeLeft(raid.timeRemaining);

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        GuildTopBar(
          title: 'Guild Raid',
          subtitle: 'One boss, one shared HP bar',
          onBack: onBack,
          trailing:
              GuildPill(timeLeft, AppColors.red, icon: Icons.schedule_rounded),
        ),
        _BossHero(raid: raid),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  GuildPill(
                      'HP scaled for ${raid.guildSizeAtStart} '
                      '${raid.guildSizeAtStart == 1 ? 'member' : 'members'}',
                      const Color(0xFFcbd5e4),
                      icon: Icons.groups_rounded),
                  GuildPill('+${guildNum(raid.rewardXp)} XP', AppColors.orange,
                      icon: Icons.bolt_rounded),
                  if (raid.maxHp != raid.baseMaxHp)
                    GuildPill('Base ${guildNum(raid.baseMaxHp)} HP',
                        AppColors.textSecondary),
                ],
              ),
              if (mine != null) ...[
                const SizedBox(height: 12),
                GuildCard(
                  borderColor: const Color(0xFF2b5fb0),
                  child: Row(
                    children: [
                      GuildAvatar(emoji: mine.avatarEmoji, name: mine.username),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const GuildLabel('Your damage'),
                            const SizedBox(height: 3),
                            Text.rich(
                              TextSpan(
                                text: guildNum(mine.damageDealt),
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900),
                                children: [
                                  TextSpan(
                                    text: raid.totalDamage <= 0
                                        ? ''
                                        : '  ${(mine.damageDealt * 100 / raid.totalDamage).round()}% of total',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mine.isMvp)
                        const GuildPill('MVP pace', AppColors.green,
                            icon: Icons.bolt_rounded),
                    ],
                  ),
                ),
              ],
              const GuildSectionHeader('Contributions'),
              if (ranked.isEmpty)
                const GuildInfoStrip(
                  icon: Icons.bolt_rounded,
                  label: 'No damage yet',
                  value: 'Log a workout to hit the boss first.',
                )
              else
                _ContributionRace(
                    ranked: ranked.take(8).toList(), topDamage: topDamage),
              const GuildSectionHeader('Victory rewards'),
              Row(
                children: [
                  Expanded(
                    child: _RewardTile(
                      label: 'Every member',
                      value: '+${guildNum(raid.rewardXp)}',
                      unit: 'XP',
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RewardTile(
                      label: 'MVP bonus',
                      value: raid.mvpBonusXp > 0
                          ? '+${guildNum(raid.mvpBonusXp)}'
                          : 'Top damage',
                      unit: raid.mvpBonusXp > 0 ? 'XP' : '',
                      color: kGuildGold,
                      crown: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GuildButton(
                label: 'Raid history',
                icon: Icons.history_rounded,
                onTap: onHistory,
                style: GuildButtonStyle.ghost,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BossHero extends StatelessWidget {
  final GuildRaid raid;
  const _BossHero({required this.raid});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2b5fb0)),
        gradient: const RadialGradient(
          center: Alignment(0, -.6),
          radius: 1.2,
          colors: [Color(0xFF1a3a70), Color(0xFF0a1220)],
        ),
      ),
      child: Column(
        children: [
          GuildBossFrame(icon: raid.bossIcon, size: 108),
          const SizedBox(height: 10),
          const GuildLabel('Active boss'),
          const SizedBox(height: 4),
          Text(
            raid.bossName,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          GuildHpBar(percent: raid.hpPercent, height: 16),
          const SizedBox(height: 7),
          Row(
            children: [
              Text.rich(
                TextSpan(
                  text: guildNum(raid.totalDamage),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                      text: ' / ${guildNum(raid.maxHp)} HP',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text('${(raid.hpPercent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Contributions ranking as a "bar race": when damage comes in, every bar
/// and number animates to its new value first, then the rows glide into the
/// new order. A member who climbs gets a burst and a "+N ▲" badge.
class _ContributionRace extends StatefulWidget {
  final List<GuildRaidContribution> ranked;
  final int topDamage;
  const _ContributionRace({required this.ranked, required this.topDamage});

  @override
  State<_ContributionRace> createState() => _ContributionRaceState();
}

class _ContributionRaceState extends State<_ContributionRace> {
  static const _tileH = 60.0, _gap = 8.0;
  late List<String> _order = [for (final c in widget.ranked) c.userId];
  final _keys = <String, GlobalKey>{};
  Timer? _reorder;

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  void didUpdateWidget(_ContributionRace old) {
    super.didUpdateWidget(old);
    final next = [for (final c in widget.ranked) c.userId];
    if (listEquals(next, _order)) return;
    final oldRank = {for (final (i, id) in _order.indexed) id: i};
    if (!RewardFx.enabled(context)) {
      _order = next;
      return;
    }
    // New members slot in at the bottom until the race settles.
    _order = [
      ..._order.where(next.contains),
      ...next.where((id) => !_order.contains(id))
    ];
    _reorder?.cancel();
    _reorder = Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      setState(() => _order = next);
      for (final (i, id) in next.indexed) {
        final was = oldRank[id];
        if (was == null || was <= i) continue;
        Future.delayed(const Duration(milliseconds: 450), () {
          if (!mounted) return;
          final r = RewardFx.rectOf(_keyFor(id));
          if (r == null) return;
          final badge = Offset(r.left + 25, r.center.dy);
          RewardFx.burst(context, badge, kGuildGold, count: 14, distance: 34);
          RewardFx.burst(context, badge, AppColors.blue,
              count: 8, distance: 24);
          RewardFx.floatText(context, Offset(r.right - 40, r.top),
              '+${was - i} ▲', AppColors.green,
              fontSize: 12,
              rise: 20,
              duration: const Duration(milliseconds: 1400));
        });
      }
    });
  }

  @override
  void dispose() {
    _reorder?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final c in widget.ranked) c.userId: c};
    final ids = _order.where(byId.containsKey).toList();
    final slot = _tileH + _gap;
    return SizedBox(
      height: ids.length * slot,
      child: Stack(
        children: [
          for (final (i, id) in ids.indexed)
            AnimatedPositioned(
              key: ValueKey(id),
              duration: AppMotion.duration(
                  context, const Duration(milliseconds: 650)),
              curve: const Cubic(.3, .8, .3, 1),
              left: 0,
              right: 0,
              top: i * slot,
              height: _tileH,
              child: KeyedSubtree(
                key: _keyFor(id),
                child: _ContributionTile(
                    contribution: byId[id]!, topDamage: widget.topDamage),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final GuildRaidContribution contribution;
  final int topDamage;
  const _ContributionTile(
      {required this.contribution, required this.topDamage});

  @override
  Widget build(BuildContext context) {
    final ratio = topDamage <= 0 ? 0.0 : contribution.damageDealt / topDamage;
    final raceDuration =
        AppMotion.duration(context, const Duration(milliseconds: 900));
    final (Color rankBg, Color rankFg) = switch (contribution.rank) {
      1 => (kGuildGold, const Color(0xFF2a1a00)),
      2 => (const Color(0xFFcdd6e4), const Color(0xFF1b2433)),
      3 => (const Color(0xFFd99160), const Color(0xFF2b1204)),
      _ => (const Color(0xFF16233a), const Color(0xFFc9d5e6)),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0b1526),
          border: Border.all(color: kGuildLine),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: ratio.clamp(0.0, 1.0).toDouble()),
                  duration: raceDuration,
                  curve: const Cubic(.3, .7, .3, 1),
                  builder: (_, v, child) =>
                      FractionallySizedBox(widthFactor: v, child: child),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x332f6fe0), Color(0x052f6fe0)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rankBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FlipSwap(
                      value: contribution.rank,
                      child: Text('${contribution.rank}',
                          style: TextStyle(
                              color: rankFg,
                              fontSize: 12,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GuildAvatar(
                      emoji: contribution.avatarEmoji,
                      name: contribution.username,
                      size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            contribution.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (contribution.isMvp) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [kGuildGoldLight, Color(0xFFe0a11c)]),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text('MVP',
                                style: TextStyle(
                                    color: Color(0xFF2a1a00),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: contribution.damageDealt.toDouble()),
                    duration: raceDuration,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(guildNum(v.round()),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool crown;

  const _RewardTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0b1526),
        border:
            Border.all(color: crown ? color.withValues(alpha: .4) : kGuildLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, Color.lerp(color, Colors.black, .45)!],
              ),
            ),
            child: crown
                ? const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFF2a1a00), size: 22)
                : const Text('XP',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.isEmpty ? value : '$value $unit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Boss picker for leaders/officers starting a raid.
class GuildStartRaidView extends ConsumerWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onStart;

  const GuildStartRaidView(
      {super.key, required this.onBack, required this.onStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bosses = ref.watch(guildRaidBossesProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        GuildTopBar(
            title: 'Start Raid',
            subtitle: 'Pick a boss for the whole guild',
            onBack: onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: bosses.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            ),
            error: (error, _) => GuildInfoStrip(
              icon: Icons.error_outline_rounded,
              label: 'Bosses unavailable',
              value: error.toString(),
            ),
            data: (items) => Column(
              children: [
                for (final boss in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BossOption(
                        boss: boss, onStart: () => onStart(boss.id)),
                  ),
                if (items.isEmpty)
                  const GuildInfoStrip(
                    icon: Icons.warning_rounded,
                    label: 'No raid bosses',
                    value: 'Unlock bosses on the map first.',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BossOption extends StatelessWidget {
  final GuildRaidBoss boss;
  final VoidCallback onStart;
  const _BossOption({required this.boss, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GuildCard(
      child: Row(
        children: [
          GuildBossFrame(icon: boss.icon, size: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(boss.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    GuildPill('${guildNum(boss.maxHp)} HP', AppColors.red),
                    GuildPill(
                        '+${guildNum(boss.rewardXp)} XP', AppColors.orange),
                    GuildPill('${boss.timerDays}d', AppColors.textSecondary,
                        icon: Icons.schedule_rounded),
                    if (boss.isMini) const GuildPill('Mini', AppColors.blue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GuildButton(
            label: 'Start',
            onTap: onStart,
            compact: true,
            expand: false,
            style: GuildButtonStyle.gold,
          ),
        ],
      ),
    );
  }
}

/// Defeated / expired raids.
class GuildRaidHistoryView extends ConsumerWidget {
  final VoidCallback onBack;
  const GuildRaidHistoryView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(guildRaidHistoryProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        GuildTopBar(
            title: 'Raid History',
            subtitle: 'Defeated and expired raids',
            onBack: onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: history.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: AppColors.blue),
              ),
            ),
            error: (error, _) => GuildInfoStrip(
              icon: Icons.error_outline_rounded,
              label: 'History unavailable',
              value: ref.read(guildServiceProvider).messageFor(error),
            ),
            data: (raids) => Column(
              children: [
                for (final raid in raids)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryCard(raid: raid),
                  ),
                if (raids.isEmpty)
                  const GuildInfoStrip(
                    icon: Icons.history_rounded,
                    label: 'No completed raids',
                    value: 'Defeated and expired raids will appear here.',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _compactDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

class _HistoryCard extends StatelessWidget {
  final GuildRaid raid;
  const _HistoryCard({required this.raid});

  @override
  Widget build(BuildContext context) {
    final won = raid.isDefeated;
    final color = won ? AppColors.green : AppColors.textSecondary;
    final endedAt = won ? raid.defeatedAt : raid.expiresAt;
    final reward = won
        ? (raid.rewardClaimed
            ? '+${guildNum(raid.rewardXp)} XP claimed'
            : '+${guildNum(raid.rewardXp)} XP pending')
        : 'No reward';
    return GuildCard(
      borderColor: color.withValues(alpha: .4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GuildBossFrame(icon: raid.bossIcon, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      won ? 'DEFEATED' : 'EXPIRED',
                      style: TextStyle(
                          color: color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8),
                    ),
                    const SizedBox(height: 2),
                    Text(raid.bossName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(_compactDate(endedAt),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
              GuildPill(
                  reward,
                  won
                      ? (raid.rewardClaimed
                          ? AppColors.green
                          : AppColors.orange)
                      : AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          GuildHpBar(percent: raid.hpPercent, height: 10),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${guildNum(raid.totalDamage)} / ${guildNum(raid.maxHp)} HP',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(won ? 'Cleared' : '${guildNum(raid.remainingHp)} HP missed',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11.5)),
            ],
          ),
          if (won && raid.mvpUsername != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kGuildGold.withValues(alpha: .08),
                border: Border.all(color: kGuildGold.withValues(alpha: .28)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      color: kGuildGold, size: 18),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${raid.mvpUsername} dealt ${guildNum(raid.mvpDamage)} damage and received +${guildNum(raid.mvpBonusXp)} XP.',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (raid.contributions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const GuildLabel('Contribution ranking'),
            const SizedBox(height: 6),
            for (final c in raid.contributions.take(5))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text('#${c.rank}',
                          style: TextStyle(
                              color: c.isMvp ? kGuildGold : AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                    Expanded(
                      child: Text(c.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                    ),
                    Text(guildNum(c.damageDealt),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
