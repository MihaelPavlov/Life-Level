import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/level_up_notifier.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../../boss/models/boss_list_item.dart';
import '../../boss/providers/boss_provider.dart';
import '../../map/models/map_models.dart';
import '../../map/node_detail_sheet.dart';
import '../providers/map_journey_provider.dart';
import '../widgets/home_card.dart';
import '../widgets/home_hero_button.dart';
import '../widgets/home_progress_bar.dart';

/// The single morphing hero card at the top of home. Collapses the old
/// standalone `HomeBossCard` plus the standalone map-progress card into
/// one surface that lives in one of three states:
///
///  * Traveling  — blue glow, distance progress, "View on map"
///  * Arrived    — green glow, 100% distance, "Enter node"
///  * Boss Raid  — red glow, boss HP bar, "Fight"  (takes priority)
///
/// Matches `.home3-hero` variants in design-mockup/home/home-v3.html.
class HomeAdventureHero extends ConsumerWidget {
  final VoidCallback? onSync;

  const HomeAdventureHero({super.key, this.onSync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bossAsync = ref.watch(bossListProvider);
    final mapAsync = ref.watch(mapJourneyProvider);

    // Boss raid takes priority over map progress (per mockup screen 3).
    final activeBoss = bossAsync.valueOrNull
        ?.where((b) => b.isActive)
        .toList()
        .firstOrNull;
    if (activeBoss != null) {
      return _BossVariant(boss: activeBoss, onSync: onSync);
    }

    final data = mapAsync.valueOrNull;
    if (data == null) {
      return const _PlaceholderVariant();
    }

    final progress = data.userProgress;
    final isTraveling = progress.currentEdgeId != null;
    final destNode = progress.destinationNodeId != null
        ? data.nodes
            .where((n) => n.id == progress.destinationNodeId)
            .firstOrNull
        : null;

    final isArrived = !isTraveling &&
        destNode != null &&
        (destNode.userState?.isCurrentNode ?? false);

    if (destNode == null && !isTraveling) {
      return const _NoDestinationVariant();
    }

    if (isArrived) {
      return _ArrivedVariant(
        node: destNode,
        onSync: onSync,
        onEnter: () => _openNodeDetailSheet(context, ref, destNode, data),
      );
    }

    return _TravelingVariant(
      data: data,
      destNode: destNode,
      onSync: onSync,
      onViewMap: () => NavTabNotifier.switchTo('map'),
    );
  }

  Future<void> _openNodeDetailSheet(
    BuildContext context,
    WidgetRef ref,
    MapNodeModel node,
    MapFullData data,
  ) async {
    final cur = data.userProgress.currentNodeId;
    final edge = data.edges
        .where((e) =>
            (e.fromNodeId == cur && e.toNodeId == node.id) ||
            (e.isBidirectional &&
                e.toNodeId == cur &&
                e.fromNodeId == node.id))
        .firstOrNull;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NodeDetailSheet(
        node: node,
        isAdjacent: edge != null,
        distanceKm: edge?.distanceKm,
        userProgress: data.userProgress,
        onDestinationSet: () => ref.invalidate(mapJourneyProvider),
        onRefresh: () => ref.invalidate(mapJourneyProvider),
        onLevelUp: (lvl) => LevelUpNotifier.notify(lvl),
      ),
    );
    ref.invalidate(mapJourneyProvider);
  }
}

// ── TRAVELING ─────────────────────────────────────────────────────────────────
class _TravelingVariant extends StatelessWidget {
  final MapFullData data;
  final MapNodeModel? destNode;
  final VoidCallback? onSync;
  final VoidCallback onViewMap;

  const _TravelingVariant({
    required this.data,
    required this.destNode,
    required this.onSync,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = data.userProgress;
    final activeEdge = data.edges
        .where((e) => e.id == progress.currentEdgeId)
        .firstOrNull;
    final double edgeProgress =
        (activeEdge != null && activeEdge.distanceKm > 0)
            ? (progress.distanceTraveledOnEdge / activeEdge.distanceKm)
                .clamp(0.0, 1.0)
            : 0.0;
    final remaining = activeEdge != null
        ? (activeEdge.distanceKm - progress.distanceTraveledOnEdge)
            .clamp(0.0, double.infinity)
        : 0.0;

    final heroLabel =
        'CURRENT ADVENTURE \u00B7 ${remaining.toStringAsFixed(1)} KM TO GO';
    final title = destNode?.name ?? 'Unknown destination';
    final sub = destNode?.description ??
        'Keep logging workouts to close the distance.';

    return _HeroShell(
      accent: AppColors.blue,
      label: heroLabel,
      labelColor: AppColors.blue,
      title: title,
      sub: sub,
      barLabel: 'Distance travelled',
      barValue:
          '${progress.distanceTraveledOnEdge.toStringAsFixed(1)} / ${activeEdge?.distanceKm.toStringAsFixed(1) ?? '?'} km',
      barValueColor: AppColors.textPrimary,
      barProgress: edgeProgress,
      barColors: const [AppColors.blue, AppColors.purple],
      primaryLabel: 'View on map \u2192',
      primaryStyle: HomeHeroButtonStyle.solidBlue,
      onPrimary: onViewMap,
      onSync: onSync,
    );
  }
}

// ── ARRIVED ───────────────────────────────────────────────────────────────────
class _ArrivedVariant extends StatelessWidget {
  final MapNodeModel node;
  final VoidCallback? onSync;
  final VoidCallback onEnter;

  const _ArrivedVariant({
    required this.node,
    required this.onSync,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return _HeroShell(
      accent: AppColors.green,
      label: 'ARRIVED \u00B7 CHALLENGE UNLOCKED',
      labelColor: AppColors.green,
      title: node.name,
      sub: node.description ??
          'You reached the gates. Complete the challenge to claim loot.',
      barLabel: 'Distance travelled',
      barValue: 'Arrived \u2713',
      barValueColor: AppColors.green,
      barProgress: 1.0,
      barColors: const [AppColors.green, AppColors.green],
      primaryLabel: 'Enter node \u2192',
      primaryStyle: HomeHeroButtonStyle.solidGreen,
      onPrimary: onEnter,
      onSync: onSync,
    );
  }
}

// ── BOSS RAID ─────────────────────────────────────────────────────────────────
class _BossVariant extends StatelessWidget {
  final BossListItem boss;
  final VoidCallback? onSync;

  const _BossVariant({required this.boss, required this.onSync});

  @override
  Widget build(BuildContext context) {
    final remaining = boss.timeRemaining;
    final timer =
        remaining != null ? _fmtDuration(remaining) : '${boss.timerDays}d';
    final hpRemaining = boss.hpRemaining;
    final hpProgress = boss.maxHp > 0 ? hpRemaining / boss.maxHp : 0.0;

    return _HeroShell(
      accent: AppColors.red,
      label: '\u2694\uFE0F BOSS RAID \u00B7 $timer LEFT',
      labelColor: AppColors.red,
      title: boss.name,
      sub:
          'Raid active. Every workout you log deals damage to ${boss.name}.',
      barLabel: 'Boss HP',
      barValue:
          '${_fmtNumber(hpRemaining)} / ${_fmtNumber(boss.maxHp)}',
      barValueColor: AppColors.red,
      barProgress: hpProgress,
      barColors: const [AppColors.red, AppColors.redDark],
      primaryLabel: 'Fight \u2192',
      primaryStyle: HomeHeroButtonStyle.solidRed,
      onPrimary: () => NavTabNotifier.switchTo('boss'),
      onSync: onSync,
    );
  }

  static String _fmtDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  static String _fmtNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

// ── No destination set (fallback) ─────────────────────────────────────────────
class _NoDestinationVariant extends StatelessWidget {
  const _NoDestinationVariant();

  @override
  Widget build(BuildContext context) {
    return _HeroShell(
      accent: AppColors.blue,
      label: 'CURRENT ADVENTURE \u00B7 NO DESTINATION',
      labelColor: AppColors.blue,
      title: 'Pick your next node',
      sub: 'Open the map to set a destination and start travelling.',
      barLabel: 'Progress',
      barValue: '\u2014',
      barValueColor: AppColors.textSecondary,
      barProgress: 0.0,
      barColors: const [AppColors.blue, AppColors.purple],
      primaryLabel: 'Open map \u2192',
      primaryStyle: HomeHeroButtonStyle.solidBlue,
      onPrimary: () => NavTabNotifier.switchTo('map'),
      onSync: null,
    );
  }
}

// ── Placeholder shown while the map provider is still loading ────────────────
class _PlaceholderVariant extends StatelessWidget {
  const _PlaceholderVariant();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: AppColors.blue,
        strokeWidth: 2,
      ),
    );
  }
}

// ── Shared hero shell (visuals) ───────────────────────────────────────────────
class _HeroShell extends StatelessWidget {
  final Color accent;
  final String label;
  final Color labelColor;
  final String title;
  final String sub;
  final String barLabel;
  final String barValue;
  final Color barValueColor;
  final double barProgress;
  final List<Color> barColors;
  final String primaryLabel;
  final HomeHeroButtonStyle primaryStyle;
  final VoidCallback? onPrimary;
  final VoidCallback? onSync;

  const _HeroShell({
    required this.accent,
    required this.label,
    required this.labelColor,
    required this.title,
    required this.sub,
    required this.barLabel,
    required this.barValue,
    required this.barValueColor,
    required this.barProgress,
    required this.barColors,
    required this.primaryLabel,
    required this.primaryStyle,
    required this.onPrimary,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      borderColor: accent.withValues(alpha: 0.4),
      glowColor: accent.withValues(alpha: 0.12),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                barLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                barValue,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: barValueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HomeProgressBar(
            progress: barProgress,
            colors: barColors,
            height: 10,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              HomeHeroButton(
                label: '\u27F3 Sync',
                style: HomeHeroButtonStyle.ghost,
                onTap: onSync,
              ),
              const SizedBox(width: 8),
              HomeHeroButton(
                label: primaryLabel,
                style: primaryStyle,
                onTap: onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
