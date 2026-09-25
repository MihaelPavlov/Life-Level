import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/achievement_models.dart';
import '../providers/achievements_provider.dart';
import 'reward_road_screen.dart';
import 'road_fx.dart';
import 'road_meta.dart';
import 'road_widgets.dart';

/// Achievements home: one clear action at the top (claim what's ready), the
/// road you're closest on, and every road as a tile.
class RewardRoadsHub extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const RewardRoadsHub({super.key, this.onClose});

  @override
  ConsumerState<RewardRoadsHub> createState() => _RewardRoadsHubState();
}

class _RewardRoadsHubState extends ConsumerState<RewardRoadsHub> {
  final _coinAnchor = FxAnchor();
  final _gemAnchor = FxAnchor();
  final _barAnchor = FxAnchor();
  AchievementWallet? _wallet;
  bool _busy = false;

  void _openRoad(String category) {
    Navigator.of(context)
        .push(AppRoute(builder: (_) => RewardRoadScreen(category: category)));
  }

  Future<void> _claimAll(AchievementRoadsData data) async {
    if (_busy) return;
    setState(() => _busy = true);
    final notifier = ref.read(achievementRoadsProvider.notifier);
    try {
      final result = await notifier.claimAll();
      if (!mounted) return;
      final bar = _barAnchor.rect;
      if (bar != null) {
        await flyClaimRewards(context,
            coinFrom: bar.centerRight - const Offset(120, 0),
            gemFrom: bar.centerRight - const Offset(90, 0),
            xpAt: bar.topCenter,
            coinTo: _coinAnchor,
            gemTo: _gemAnchor,
            xp: result.xp);
      }
      if (!mounted) return;
      setState(() => _wallet = result.wallet);
      await notifier.reload();
      notifier.refreshCharacter();
      if (!mounted) return;
      setState(() => _wallet = null);
      final chests = result.chestsReady.length;
      if (chests > 0) {
        AppToast.success(
            context,
            chests == 1
                ? 'A chest is ready to open'
                : '$chests chests are ready to open');
      }
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not claim. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(achievementRoadsProvider);
    final data = async.valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: AppColors.textPrimary),
                    onPressed:
                        widget.onClose ?? () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text('Achievements',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ),
                  if (data != null)
                    RoadWallet(
                      wallet: _wallet ?? data.wallet,
                      coinAnchor: _coinAnchor,
                      gemAnchor: _gemAnchor,
                    ),
                ],
              ),
            ),
            Expanded(
              child: data == null
                  ? Center(
                      child: async.hasError
                          ? TextButton(
                              onPressed: () =>
                                  ref.invalidate(achievementRoadsProvider),
                              child:
                                  const Text('Could not load. Tap to retry.'),
                            )
                          : const CircularProgressIndicator(
                              color: AppColors.blue),
                    )
                  : RefreshIndicator(
                      color: AppColors.blue,
                      onRefresh: () =>
                          ref.read(achievementRoadsProvider.notifier).reload(),
                      child: _body(data),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AchievementRoadsData data) {
    final continueRoad = _pickContinue(data.roads);
    final roads = [...data.roads]..sort((a, b) {
        int rank(AchievementRoad r) => r.hasChestReady || r.ready > 0 ? 0 : 1;
        return rank(a).compareTo(rank(b));
      });
    final readyOn = data.roads
        .where((r) => r.ready > 0)
        .map((r) => RoadMeta.of(r.category).name)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      children: [
        AnimatedSize(
          duration:
              AppMotion.duration(context, const Duration(milliseconds: 350)),
          alignment: Alignment.topCenter,
          child: data.readyCount > 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FxAnchorTarget(
                    anchor: _barAnchor,
                    child: _ReadyBar(
                      count: data.readyCount,
                      where: readyOn.join(' and '),
                      busy: _busy,
                      onClaimAll: () => _claimAll(data),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (continueRoad != null) ...[
          const RoadSectionTitle('CONTINUE'),
          const SizedBox(height: 8),
          _ContinueCard(
              road: continueRoad,
              onTap: () => _openRoad(continueRoad.category)),
          const SizedBox(height: 18),
        ],
        const RoadSectionTitle('ALL ROADS'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.45,
          children: [
            for (final r in roads)
              _RoadTile(road: r, onTap: () => _openRoad(r.category)),
          ],
        ),
      ],
    );
  }

  /// The road to nudge the player back into: an open chest first, then
  /// rewards to claim, then the stage closest to its chest.
  AchievementRoad? _pickContinue(List<AchievementRoad> roads) {
    final open = roads.where((r) => !r.isComplete).toList();
    if (open.isEmpty) return null;
    double score(AchievementRoad r) {
      final s = r.current!;
      if (s.chestReady) return 3;
      if (r.ready > 0) return 2 + r.ready / 100;
      return s.total == 0 ? 0 : s.unlocked / s.total;
    }

    open.sort((a, b) => score(b).compareTo(score(a)));
    return open.first;
  }
}

class _ReadyBar extends StatelessWidget {
  final int count;
  final String where;
  final bool busy;
  final VoidCallback onClaimAll;
  const _ReadyBar({
    required this.count,
    required this.where,
    required this.busy,
    required this.onClaimAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: [
          kRoadReady.withValues(alpha: .18),
          AppColors.surface,
        ], stops: const [
          0,
          .8
        ]),
        border: Border.all(color: kRoadReady.withValues(alpha: .6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kRoadReady,
              boxShadow: [
                BoxShadow(
                    color: kRoadReady.withValues(alpha: .55), blurRadius: 14)
              ],
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1004))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    count == 1
                        ? 'Reward ready to claim'
                        : 'Rewards ready to claim',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (where.isNotEmpty)
                  Text('On $where',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFFC9B38A))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: busy ? null : onClaimAll,
              style: FilledButton.styleFrom(
                backgroundColor: kRoadReady,
                foregroundColor: const Color(0xFF1A1004),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              child: const Text('Claim all'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final AchievementRoad road;
  final VoidCallback onTap;
  const _ContinueCard({required this.road, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = road.current!;
    final meta = RoadMeta.of(road.category);
    final c = tierColor(s.tier);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.3,
              colors: [c.withValues(alpha: .18), Colors.transparent],
            ),
            border: Border.all(
                color: s.chestReady ? kRoadReady : c.withValues(alpha: .5),
                width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${meta.emoji} ${meta.name} · Stage ${road.currentStage + 1} of ${road.stages.length}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c)),
                        const SizedBox(height: 4),
                        Text(stageHeadline(s),
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: s.chestReady
                                    ? kRoadReady
                                    : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(AppIcons.shopChestForKey(s.chestKey),
                      width: 70, height: 70),
                ],
              ),
              const SizedBox(height: 12),
              StagePips(stage: s, height: 6),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: StageLegend(stage: s)),
                  Text(s.chestReady ? 'Open chest →' : 'Open road →',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: s.chestReady ? kRoadReady : c)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoadTile extends StatelessWidget {
  final AchievementRoad road;
  final VoidCallback onTap;
  const _RoadTile({required this.road, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = RoadMeta.of(road.category);
    final (String? badge, Color badgeBg, Color badgeFg) = road.hasChestReady
        ? ('Chest ready', kRoadReady, const Color(0xFF1A1004))
        : road.ready > 0
            ? ('${road.ready} ready', kRoadReady, const Color(0xFF1A1004))
            : road.isComplete
                ? ('Complete', kRoadDone.withValues(alpha: .2), kRoadDone)
                : (null, Colors.transparent, Colors.transparent);
    final pct = road.total == 0 ? 0.0 : road.claimed / road.total;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF21262D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(meta.emoji,
                        style: const TextStyle(fontSize: 19, height: 1)),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(99)),
                      child: Text(badge,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badgeFg)),
                    ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(meta.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ),
                  Text('${road.claimed} / ${road.total}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: pct < .03 && road.claimed > 0 ? .03 : pct,
                  minHeight: 5,
                  backgroundColor: const Color(0xFF1E2632),
                  color: meta.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
