import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/services/shell_overlay_notifier.dart';
import '../../leaderboard/leaderboard_screen.dart';
import '../../rewards/rewards_screen.dart';
import '../../map/screens/region_chests_screen.dart';
import '../../streak/widgets/streak_detail_sheet.dart';
import '../../unlocks/models/unlock_catalog.dart';
import '../../unlocks/models/unlock_models.dart';
import '../../unlocks/providers/unlocks_provider.dart';
import '../../unlocks/tour/tour_target.dart';
import '../../unlocks/tour/tours/unlock_tours.dart';
import '../../unlocks/widgets/unlock_badges.dart';
import '../providers/adventure_hub_status_provider.dart';
import 'home_recent_activities_card.dart' show showActivityJournalSheet;

/// Horizontally-scrollable row of quick entry points into the game's
/// systems — daily rewards, bosses, streak, workout journal, guild,
/// titles/ranks, and talents — matching the "Adventure Hub" reference
/// layout. Sits right under the hero-stage card.
class HomeAdventureHub extends ConsumerWidget {
  const HomeAdventureHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalsAsync = ref.watch(adventureHubSignalsProvider);
    final signals = signalsAsync.isLoading
        ? AdventureHubSignals.empty
        : signalsAsync.valueOrNull ?? AdventureHubSignals.empty;
    final unlocks = ref.watch(unlocksSnapshotProvider);
    final tiles = _orderedTiles(context, signals, unlocks);

    return TourTarget(
      id: TourIds.homeHub,
      child: Padding(
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
                    _slot(context, tiles[i], unlocks),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slot(
      BuildContext context, _HubTileModel tile, UnlocksSnapshot unlocks) {
    final key = tile.unlockKey;
    final locked = key != null && !unlocks.isUnlocked(key);
    final fresh = key != null && unlocks.isFresh(key);
    final hubTile = _HubTile(
      icon: AppIconImage(tile.iconAsset, size: 30),
      iconTargetId: key == null ? null : 'icon.$key',
      label: tile.label,
      showBadge: tile.hasUpdate && !locked,
      locked: locked,
      fresh: fresh,
      onTap: locked ? () => showLockedHint(context, key) : tile.onTap,
    );
    return KeyedSubtree(
      key: ValueKey(tile.label),
      child:
          key == null ? hubTile : TourTarget(id: 'slot.$key', child: hubTile),
    );
  }

  List<_HubTileModel> _orderedTiles(
    BuildContext context,
    AdventureHubSignals signals,
    UnlocksSnapshot unlocks,
  ) {
    final tiles = [
      _HubTileModel(
        iconAsset: AppIcons.rewardDailyBonus,
        label: 'Rewards',
        hasUpdate: signals.rewards,
        onTap: () => _openRewards(context),
      ),
      _HubTileModel(
        unlockKey: UnlockKeys.bosses,
        iconAsset: AppIcons.ringBoss,
        label: 'Bosses',
        hasUpdate: signals.bosses,
        onTap: _openBosses,
      ),
      _HubTileModel(
        iconAsset: AppIcons.seasonAdventureHub,
        label: 'Season',
        hasUpdate: signals.season,
        onTap: _openSeason,
      ),
      _HubTileModel(
        iconAsset: AppIcons.rewardStreakFire,
        label: 'Streak',
        hasUpdate: signals.streak,
        onTap: () => showStreakDetailSheet(context),
      ),
      _HubTileModel(
        iconAsset: AppIcons.homeJournalIcon,
        label: 'Journal',
        hasUpdate: false,
        onTap: () => showActivityJournalSheet(context),
      ),
      _HubTileModel(
        unlockKey: UnlockKeys.leaderboard,
        iconAsset: AppIcons.ringLeaderboard,
        label: 'Leaderboard',
        hasUpdate: signals.leaderboard,
        onTap: () => LeaderboardScreen.open(context),
      ),
      _HubTileModel(
        unlockKey: UnlockKeys.achievements,
        iconAsset: AppIcons.rankChampion,
        label: 'Achievements',
        hasUpdate: signals.achievements,
        onTap: _openAchievements,
      ),
      _HubTileModel(
        unlockKey: UnlockKeys.guild,
        iconAsset: AppIcons.ringGuild,
        label: 'Guild',
        hasUpdate: false,
        onTap: _openGuild,
      ),
      _HubTileModel(
        unlockKey: UnlockKeys.ranks,
        iconAsset: AppIcons.ringTitles,
        label: 'Ranks',
        hasUpdate: signals.titles,
        onTap: _openTitles,
      ),
      _HubTileModel(
        unlockKey: UnlockKeys.talents,
        iconAsset: AppIcons.talentCrystalIcon,
        label: 'Talents',
        hasUpdate: signals.talents,
        onTap: _openTalents,
      ),
      _HubTileModel(
        unlockKey: UnlockKeys.chests,
        iconAsset: AppIcons.regionChestsHubIcon,
        label: 'Region Chests',
        hasUpdate: signals.chests,
        onTap: () => _openRegionChests(context),
      ),
    ];

    final indexed = [
      for (var i = 0; i < tiles.length; i++) (index: i, tile: tiles[i]),
    ];
    bool isLocked(_HubTileModel t) =>
        t.unlockKey != null && !unlocks.isUnlocked(t.unlockKey!);
    indexed.sort((a, b) {
      // Keep each usable shortcut in a familiar position while live badges
      // refresh. Locked previews stay at the end until their feature opens.
      if (isLocked(a.tile) != isLocked(b.tile)) {
        return isLocked(a.tile) ? 1 : -1;
      }
      return a.index.compareTo(b.index);
    });

    return [for (final item in indexed) item.tile];
  }

  void _openRewards(BuildContext context) {
    showRewardsSheet(context);
  }

  void _openAchievements() {
    ShellOverlayNotifier.open('achievements');
  }

  void _openBosses() => ShellOverlayNotifier.open('boss');

  void _openGuild() => ShellOverlayNotifier.open('guild');

  void _openTitles() {
    ShellOverlayNotifier.open('titles');
  }

  void _openSeason() => ShellOverlayNotifier.open('season');

  void _openRegionChests(BuildContext context) => Navigator.push(
        context,
        AppRoute(builder: (_) => const RegionChestsScreen()),
      );

  void _openTalents() => ShellOverlayNotifier.open('talents');
}

class _HubTileModel {
  /// The guided-unlock key that opens this tile, or null if it's always open.
  final String? unlockKey;
  final String iconAsset;
  final String label;
  final bool hasUpdate;
  final VoidCallback onTap;

  const _HubTileModel({
    this.unlockKey,
    required this.iconAsset,
    required this.label,
    required this.hasUpdate,
    required this.onTap,
  });
}

class _HubTile extends StatelessWidget {
  final Widget icon;
  final String? iconTargetId;
  final String label;
  final bool showBadge;
  final bool locked;
  final bool fresh;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    this.iconTargetId,
    required this.label,
    this.showBadge = false,
    this.locked = false,
    this.fresh = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconTarget(Widget child) => iconTargetId == null
        ? child
        : TourTarget(id: iconTargetId!, child: child);
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
                  if (locked)
                    iconTarget(SizedBox(
                      width: 56,
                      height: 56,
                      child: CustomPaint(
                        painter: _DashedSquarePainter(),
                        child: Center(
                          child: Opacity(
                            opacity: .35,
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0, 0, 0, 0, 89, //
                                0, 0, 0, 0, 89,
                                0, 0, 0, 0, 89,
                                0, 0, 0, 1, 0,
                              ]),
                              child: icon,
                            ),
                          ),
                        ),
                      ),
                    ))
                  else
                    iconTarget(Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        border: Border.all(
                            color: fresh
                                ? AppColors.orange.withValues(alpha: .7)
                                : AppColors.border),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: fresh
                            ? [
                                BoxShadow(
                                    color:
                                        AppColors.orange.withValues(alpha: .35),
                                    blurRadius: 16),
                              ]
                            : null,
                      ),
                      child: Center(child: icon),
                    )),
                  if (locked)
                    const Positioned(top: 6, right: 4, child: LockBadge()),
                  if (fresh && !locked)
                    const Positioned(top: 2, right: -2, child: NewPill()),
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
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: locked
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: locked
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
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

/// Dashed rounded square: the outline of a slot that hasn't unlocked yet.
class _DashedSquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A3340)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.6), const Radius.circular(14)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedSquarePainter old) => false;
}
