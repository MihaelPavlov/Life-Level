import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/services/boss_overlay_notifier.dart';
import '../../../core/services/shell_overlay_notifier.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../boss/providers/boss_provider.dart';
import '../../guild/providers/guild_provider.dart';
import '../../modes/burn_chain/burn_chain_provider.dart';
import '../../modes/burn_chain/burn_chain_rules.dart';
import '../../season/providers/season_provider.dart';

/// One live, timed thing shown under the Adventure Hub.
class HappeningEvent {
  final String id;
  final String icon;
  final Color color;
  final String title;
  final String detail;
  final Duration timeLeft;

  /// "ends Fri 13:30" style suffix for the focus card title.
  final String endsLabel;
  final String? cta;
  final VoidCallback? onCta;

  const HappeningEvent({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.timeLeft,
    required this.endsLabel,
    this.cta,
    this.onCta,
  });
}

String formatTimeLeft(Duration d) {
  if (d.isNegative) return 'ending';
  if (d.inDays >= 3) return '${d.inDays} days';
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes.clamp(1, 59)}m';
}

String formatEndsAt(DateTime at, [DateTime? now]) {
  final local = at.toLocal();
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(local.year, local.month, local.day);
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final diff = day.difference(today).inDays;
  if (diff == 0) return '$hh:$mm';
  if (diff == 1) return 'tomorrow $hh:$mm';
  if (diff < 7) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[local.weekday - 1]} $hh:$mm';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]}';
}

/// Live, timed events from the guild raid, the player's boss fight and the
/// season, soonest-ending first. Anything the Adventure Hub or Map button
/// already covers (opening features, the journey) is not repeated here.
final happeningEventsProvider =
    Provider.autoDispose<List<HappeningEvent>>((ref) {
  final events = <HappeningEvent>[];
  final now = DateTime.now().toUtc();

  final raid = ref.watch(guildProvider).valueOrNull?.activeRaid;
  if (raid != null && !raid.isDefeated && !raid.isExpired) {
    final hpPct =
        raid.maxHp > 0 ? (raid.remainingHp / raid.maxHp * 100).round() : 0;
    events.add(HappeningEvent(
      id: 'raid',
      icon: AppIcons.ringGuild,
      color: AppColors.red,
      title: raid.bossName,
      detail: 'Your guild has it at $hpPct% HP. Every workout adds damage.',
      timeLeft: raid.expiresAt.toUtc().difference(now),
      endsLabel: formatEndsAt(raid.expiresAt),
      cta: 'Open raid',
      onCta: () => ShellOverlayNotifier.open('guild'),
    ));
  }

  final boss = ref
      .watch(bossListProvider)
      .valueOrNull
      ?.where((b) => b.isActive)
      .firstOrNull;
  final bossLeft = boss?.timeRemaining;
  if (boss != null && bossLeft != null) {
    final hpPct =
        boss.maxHp > 0 ? (boss.hpRemaining / boss.maxHp * 100).round() : 0;
    events.add(HappeningEvent(
      id: 'boss',
      icon: AppIcons.ringBoss,
      color: AppColors.red,
      title: boss.name,
      detail: '$hpPct% HP left. Every workout you log deals damage.',
      timeLeft: bossLeft,
      endsLabel: formatEndsAt(DateTime.now().add(bossLeft)),
      cta: 'Fight',
      onCta: () => BossOverlayNotifier.notifyForBoss(boss.id),
    ));
  }

  final chain = ref.watch(burnChainProvider).valueOrNull?.chain;
  final chainEnds = chain?.endsAt;
  if (chain != null && chain.phase == BurnChainPhase.live && chainEnds != null) {
    final bar = chain.bar;
    events.add(HappeningEvent(
      id: 'burn_chain',
      icon: AppIcons.rewardStreakFire,
      color: const Color(0xFFF0883E),
      title: 'Burn Chain',
      detail: bar == null
          ? 'Your first workout sets the bar.'
          : 'Next workout must beat $bar kcal to earn ×$kBurnChainBeatMultiplier.',
      timeLeft: chainEnds.toUtc().difference(now),
      endsLabel: formatEndsAt(chainEnds),
      cta: 'View chain',
      onCta: () => ShellOverlayNotifier.open('burn_chain'),
    ));
  }

  final season = ref.watch(seasonProvider).valueOrNull;
  final header = season?.season;
  if (season != null && season.hasActiveSeason && header != null) {
    final next = season.nextReward;
    events.add(HappeningEvent(
      id: 'season',
      icon: AppIcons.seasonAdventureHub,
      color: AppColors.blue,
      title: header.name,
      detail: next != null
          ? 'Tier ${season.currentTier} of ${season.tierCount}. Next reward: ${next.label}.'
          : 'Tier ${season.currentTier} of ${season.tierCount}.',
      timeLeft: header.endsAt.toUtc().difference(now),
      endsLabel: formatEndsAt(header.endsAt),
      cta: 'View season',
      onCta: () => ShellOverlayNotifier.open('season'),
    ));
  }

  events.sort((a, b) => a.timeLeft.compareTo(b.timeLeft));
  return events;
});

/// "● HAPPENING NOW": a row of timer chips and one focus card for the chip
/// that is selected (soonest-ending by default). Hidden when nothing is live.
class HomeHappeningNow extends ConsumerStatefulWidget {
  const HomeHappeningNow({super.key});

  @override
  ConsumerState<HomeHappeningNow> createState() => _HomeHappeningNowState();
}

class _HomeHappeningNowState extends ConsumerState<HomeHappeningNow>
    with SingleTickerProviderStateMixin {
  String? _focusId;
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.allowsDecorativeMotion(context)) {
      if (!_blink.isAnimating) _blink.repeat(reverse: true);
    } else {
      _blink.stop();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(happeningEventsProvider);
    if (events.isEmpty) return const SizedBox.shrink();
    final focus =
        events.firstWhere((e) => e.id == _focusId, orElse: () => events.first);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: Tween(begin: 1.0, end: .25).animate(_blink),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.red.withValues(alpha: .8),
                          blurRadius: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'HAPPENING NOW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (events.length > 1)
                const Text(
                  'Tap a chip',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final (i, e) in events.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _Chip(
                    event: e,
                    selected: e.id == focus.id,
                    onTap: () => setState(() => _focusId = e.id),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotionTokens.micro),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(.04, 0), end: Offset.zero)
                    .animate(a),
                child: child,
              ),
            ),
            child: _FocusCard(key: ValueKey(focus.id), event: focus),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final HappeningEvent event;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.event, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = event.color;
    return Semantics(
      button: true,
      selected: selected,
      label: '${event.title}, ${formatTimeLeft(event.timeLeft)} left',
      child: AppPressable(
        haptic: AppHaptic.selection,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotionTokens.micro),
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : const Color(0xFF10161F),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: c.withValues(alpha: selected ? .9 : .5),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B1017),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AppIconImage(event.icon, size: 22),
              ),
              const SizedBox(width: 8),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTimeLeft(event.timeLeft),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: c,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final HappeningEvent event;
  const _FocusCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final c = event.color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: .45)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: .14), AppColors.surface],
          stops: const [0, .6],
        ),
      ),
      child: Row(
        children: [
          AppIconImage(event.icon, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.title} · ends ${event.endsLabel}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.detail,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (event.cta != null)
            AppPressable(
              haptic: AppHaptic.light,
              onTap: event.onCta,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  event.cta!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatTimeLeft(event.timeLeft),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: c,
                  ),
                ),
                const Text(
                  'LEFT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
