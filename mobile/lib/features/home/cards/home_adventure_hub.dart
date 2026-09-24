import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/services/shell_overlay_notifier.dart';
import '../../achievements/providers/achievements_provider.dart';
import '../../character/providers/character_provider.dart';
import '../../rewards/rewards_screen.dart';
import '../../map/screens/region_chests_screen.dart';
import '../../streak/widgets/streak_detail_sheet.dart';
import '../../titles/providers/titles_provider.dart';
import '../providers/adventure_hub_status_provider.dart';
import 'home_recent_activities_card.dart' show showActivityJournalSheet;

/// Horizontally-scrollable row of quick entry points into the game's
/// systems — daily rewards, streak, workout journal, guild,
/// titles/ranks, and talents — matching the "Adventure Hub" reference
/// layout. Sits right under the hero-stage card.
class HomeAdventureHub extends ConsumerWidget {
  const HomeAdventureHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signals = ref.watch(adventureHubSignalsProvider).valueOrNull ??
        AdventureHubSignals.empty;
    final tiles = _orderedTiles(context, ref, signals);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ADVENTURE HUB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Swipe for more',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _HubTile(
                    key: ValueKey(tiles[i].label),
                    icon: AppIconImage(tiles[i].iconAsset, size: 30),
                    label: tiles[i].label,
                    showBadge: tiles[i].hasUpdate,
                    onTap: tiles[i].onTap,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_HubTileModel> _orderedTiles(
    BuildContext context,
    WidgetRef ref,
    AdventureHubSignals signals,
  ) {
    final tiles = [
      _HubTileModel(
        iconAsset: AppIcons.rewardDailyBonus,
        label: 'Rewards',
        hasUpdate: signals.rewards,
        priority: 0,
        onTap: () => _openRewards(context),
      ),
      _HubTileModel(
        iconAsset: AppIcons.rewardStreakFire,
        label: 'Streak',
        hasUpdate: signals.streak,
        priority: 5,
        onTap: () => showStreakDetailSheet(context),
      ),
      _HubTileModel(
        iconAsset: AppIcons.homeJournalIcon,
        label: 'Journal',
        hasUpdate: false,
        priority: 6,
        onTap: () => showActivityJournalSheet(context),
      ),
      _HubTileModel(
        iconAsset: AppIcons.rankChampion,
        label: 'Achievements',
        hasUpdate: signals.achievements,
        priority: 3,
        onTap: () => _openAchievements(ref),
      ),
      _HubTileModel(
        iconAsset: AppIcons.ringGuild,
        label: 'Guild',
        hasUpdate: false,
        priority: 7,
        onTap: _openGuild,
      ),
      _HubTileModel(
        iconAsset: AppIcons.ringTitles,
        label: 'Milestones',
        hasUpdate: signals.titles,
        priority: 5,
        onTap: () => _openTitles(ref),
      ),
      _HubTileModel(
        iconAsset: AppIcons.talentCrystalIcon,
        label: 'Talents',
        hasUpdate: signals.talents,
        priority: 1,
        onTap: _openTalents,
      ),
      _HubTileModel(
        iconAsset: AppIcons.seasonAdventureHub,
        label: 'Season',
        hasUpdate: signals.season,
        priority: 2,
        onTap: _openSeason,
      ),
      _HubTileModel(
        iconAsset: AppIcons.regionChestsHubIcon,
        label: 'Region Chests',
        hasUpdate: false,
        priority: 8,
        onTap: () => _openRegionChests(context),
      ),
    ];

    final indexed = [
      for (var i = 0; i < tiles.length; i++) (index: i, tile: tiles[i]),
    ];
    indexed.sort((a, b) {
      if (a.tile.hasUpdate != b.tile.hasUpdate) {
        return a.tile.hasUpdate ? -1 : 1;
      }
      if (a.tile.hasUpdate) {
        final priorityCompare = a.tile.priority.compareTo(b.tile.priority);
        if (priorityCompare != 0) return priorityCompare;
      }
      return a.index.compareTo(b.index);
    });

    return [for (final item in indexed) item.tile];
  }

  void _openRewards(BuildContext context) {
    showRewardsSheet(context);
  }

  void _openAchievements(WidgetRef ref) {
    _markAchievementsSeen(ref);
    ShellOverlayNotifier.open('achievements');
  }

  void _openGuild() => ShellOverlayNotifier.open('guild');

  void _openTitles(WidgetRef ref) {
    _markTitlesSeen(ref);
    ShellOverlayNotifier.open('titles');
  }

  void _openSeason() => ShellOverlayNotifier.open('season');

  void _openRegionChests(BuildContext context) => Navigator.push(
        context,
        AppRoute(builder: (_) => const RegionChestsScreen()),
      );

  void _openTalents() => ShellOverlayNotifier.open('talents');

  void _markTitlesSeen(WidgetRef ref) {
    final username = ref.read(characterProfileProvider).valueOrNull?.username;
    final titles = ref.read(titlesProvider).valueOrNull;
    if (username == null || titles == null) return;
    final ids = titles.earnedTitles.map((title) => title.id).toList();
    unawaited(
      ref
          .read(adventureHubSeenStoreProvider)
          .markTitlesSeen(username: username, earnedTitleIds: ids)
          .then((_) => ref.invalidate(adventureHubSignalsProvider)),
    );
  }

  void _markAchievementsSeen(WidgetRef ref) {
    final username = ref.read(characterProfileProvider).valueOrNull?.username;
    final achievements = ref.read(achievementsProvider).valueOrNull;
    if (username == null || achievements == null) return;
    final ids = achievements
        .where((achievement) => achievement.isUnlocked)
        .map((achievement) => achievement.id)
        .toList();
    unawaited(
      ref
          .read(adventureHubSeenStoreProvider)
          .markAchievementsSeen(
            username: username,
            unlockedAchievementIds: ids,
          )
          .then((_) => ref.invalidate(adventureHubSignalsProvider)),
    );
  }
}

class _HubTileModel {
  final String iconAsset;
  final String label;
  final bool hasUpdate;
  final int priority;
  final VoidCallback onTap;

  const _HubTileModel({
    required this.iconAsset,
    required this.label,
    required this.hasUpdate,
    required this.priority,
    required this.onTap,
  });
}

class _HubTile extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool showBadge;
  final VoidCallback onTap;

  const _HubTile({
    super.key,
    required this.icon,
    required this.label,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            SizedBox(
              width: 68,
              height: 66,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: icon),
                  ),
                  Positioned(
                    top: 4,
                    right: 2,
                    child: AnimatedSwitcher(
                      duration: AppMotion.duration(
                        context,
                        AppMotionTokens.micro,
                      ),
                      switchInCurve: AppMotionTokens.enterCurve,
                      switchOutCurve: AppMotionTokens.exitCurve,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: showBadge
                          ? const _HubAlertBadge(key: ValueKey('alert'))
                          : const SizedBox.shrink(key: ValueKey('clear')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              child: label.contains(' ')
                  ? Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubAlertBadge extends StatefulWidget {
  const _HubAlertBadge({super.key});

  @override
  State<_HubAlertBadge> createState() => _HubAlertBadgeState();
}

class _HubAlertBadgeState extends State<_HubAlertBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.16).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.45),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '!',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
