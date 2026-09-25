import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../models/achievement_models.dart';
import '../providers/achievements_provider.dart';
import 'road_fx.dart';
import 'road_meta.dart';
import 'road_widgets.dart';

/// One Reward Road: stage stepper, the current stage's chest goal, rewards
/// ready to claim, achievements in progress, and what comes next.
///
/// Claim timeline (matches the "Reward Roads Simplified" design):
///   0 ms     row glows, ring pulses, check stamps in
///   380 ms   coins + gems fly from the row into the header wallet, "+XP" floats
///   ~1150 ms wallet counts up and bumps
///   1750 ms  claimed rows fold away, "N done" updates
///   2050 ms  stage pieces turn green one after another
///   ~2500 ms chest wiggles, headline flashes — or, when the claim finished the
///            stage, "Stage N complete!" + gold pulse, then the chest popup
///   3000 ms  summary toast
class RewardRoadScreen extends ConsumerStatefulWidget {
  final String category;
  const RewardRoadScreen({super.key, required this.category});

  @override
  ConsumerState<RewardRoadScreen> createState() => _RewardRoadScreenState();
}

class _RewardRoadScreenState extends ConsumerState<RewardRoadScreen> {
  final _coinAnchor = FxAnchor();
  final _gemAnchor = FxAnchor();
  final _chestAnchor = FxAnchor();
  final _rowAnchors = <String, (FxAnchor, FxAnchor, FxAnchor)>{};
  final _claiming = <String>{};
  final _folded = <String>{};

  /// Wallet shown in the header. Held back while rewards are in the air so
  /// the counters tick up when they land, not when the request returns.
  AchievementWallet? _wallet;
  int? _selected;
  bool _busy = false;
  String? _completingTier;
  bool _chestAway = false;
  String? _arrivedTier;
  int _nudge = 0;
  _ToastData? _toast;
  Timer? _toastTimer;

  (FxAnchor, FxAnchor, FxAnchor) _anchorsFor(String id) =>
      _rowAnchors.putIfAbsent(id, () => (FxAnchor(), FxAnchor(), FxAnchor()));

  bool get _motion => AppMotion.isFull(context);

  Future<void> _wait(int ms) async {
    if (_motion && ms > 0) {
      await Future<void>.delayed(Duration(milliseconds: ms));
    }
  }

  void _showToast(_ToastData t) {
    _toastTimer?.cancel();
    setState(() => _toast = t);
    _toastTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _claim(AchievementRoad road, List<AchievementDto> rows) async {
    if (_busy || rows.isEmpty) return;
    final notifier = ref.read(achievementRoadsProvider.notifier);
    final started = DateTime.now();
    setState(() {
      _busy = true;
      _toast = null;
      _claiming.addAll(rows.map((a) => a.id));
    });
    AppMotion.haptic(AppHaptic.light);
    try {
      final request = rows.length == 1
          ? notifier.claim(rows.first.id)
          : notifier.claimAll(category: road.category);

      // 380 ms: rewards fly (the request runs meanwhile).
      await _wait(380);
      if (!mounted) return;
      final flights = <Future<void>>[];
      for (final (i, a) in rows.indexed) {
        final (row, coin, gem) = _anchorsFor(a.id);
        final rowRect = row.rect;
        final coinFrom = coin.center, gemFrom = gem.center;
        if (rowRect == null || coinFrom == null || gemFrom == null) continue;
        flights.add(flyClaimRewards(context,
            coinFrom: coinFrom,
            gemFrom: gemFrom,
            xpAt: Offset(rowRect.left + 80, rowRect.top - 6),
            coinTo: _coinAnchor,
            gemTo: _gemAnchor,
            xp: a.xpReward,
            delay: Duration(milliseconds: 120 * i)));
      }
      final result = await request;
      await Future.wait(flights);
      if (!mounted) return;

      // Wallet counts up + bumps (600 ms), then the rows fold away.
      setState(() => _wallet = result.wallet);
      AppMotion.haptic(AppHaptic.selection);
      await _wait(600);
      if (!mounted) return;
      setState(() => _folded.addAll(result.claimedIds));
      await _wait(300);

      final finished = result.chestsReady
          .where((c) => c.$1 == road.category)
          .map((c) => c.$2)
          .toList();
      final completing = finished.isNotEmpty ? finished.first : null;
      await notifier.reload();
      notifier.refreshCharacter();
      if (!mounted) return;
      setState(() {
        _claiming.clear();
        _folded.clear();
        _wallet = null; // back to the live balance
        if (completing != null) {
          _completingTier = completing;
          final i = road.stages.indexWhere((s) => s.tier == completing);
          if (i >= 0) _selected = i;
        }
      });

      // Pieces pop green one by one (200 ms apart).
      await _wait(200 * rows.length + 250);
      if (!mounted) return;

      if (completing != null) {
        // "Stage N complete!", gold pulse ×2 and chest hops, then the popup.
        await _wait(1000);
        if (!mounted) return;
        await _openChest(completing, alreadyCelebrating: true);
        return;
      }
      setState(() => _nudge++);
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      await _wait((3000 - elapsed).clamp(0, 800));
      if (!mounted) return;
      _showToast(_ToastData.claimed(result, rows));
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not claim. Try again.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _claiming.clear();
          _folded.clear();
        });
      }
    }
  }

  Future<void> _openChest(String tier,
      {bool alreadyCelebrating = false}) async {
    final notifier = ref.read(achievementRoadsProvider.notifier);
    final road =
        ref.read(achievementRoadsProvider).valueOrNull?.road(widget.category);
    final index = road?.stages.indexWhere((s) => s.tier == tier) ?? -1;
    if (road == null || index < 0) return;

    setState(() {
      _busy = true;
      _completingTier = tier;
      _selected = index;
    });
    if (!alreadyCelebrating) await _wait(1000);
    try {
      final result = await notifier.openStageChest(road.category, tier);
      if (!mounted) return;
      setState(() => _chestAway = true);
      await showStageChestPopup(context,
          result: result,
          stageNumber: index + 1,
          coinTo: _coinAnchor,
          gemTo: _gemAnchor);
      if (!mounted) return;
      // Counters count up, then the road moves on: stepper advances, the next
      // stage's card slides in and its chest drops in.
      setState(() => _wallet = result.wallet);
      await notifier.reload();
      notifier.refreshCharacter();
      if (!mounted) return;
      final next =
          ref.read(achievementRoadsProvider).valueOrNull?.road(widget.category);
      setState(() {
        _completingTier = null;
        _chestAway = false;
        _selected = null; // follow the road to its new current stage
        _arrivedTier = next?.current?.tier;
        _wallet = null;
      });
      await _wait(500);
      if (!mounted) return;
      _showToast(_ToastData.chest(
          result,
          next?.current == null
              ? 'Road complete'
              : 'Stage ${next!.currentStage + 1} is now open'));
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not open the chest. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _completingTier = null;
          _chestAway = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(achievementRoadsProvider);
    final data = async.valueOrNull;
    final road = data?.road(widget.category);
    final meta = RoadMeta.of(widget.category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back to all roads',
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text('${meta.emoji} ${meta.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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
                  child: road == null
                      ? Center(
                          child: async.hasError
                              ? const Text('Could not load this road.',
                                  style:
                                      TextStyle(color: AppColors.textSecondary))
                              : const CircularProgressIndicator(
                                  color: AppColors.blue),
                        )
                      : _body(road),
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: _RoadToast(data: _toast),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AchievementRoad road) {
    final current =
        road.isComplete ? road.stages.length - 1 : road.currentStage;
    final selected = (_selected ?? current).clamp(0, road.stages.length - 1);
    final stage = road.stages[selected];
    final ready = [
      for (final s in road.stages) ...s.achievements.where((a) => a.isReady),
    ];
    final inProgress = stage.achievements.where((a) => !a.isUnlocked).toList()
      ..sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
    final done = stage.achievements.where((a) => a.isClaimed).toList();
    final next =
        selected + 1 < road.stages.length ? road.stages[selected + 1] : null;
    final canOpen = stage.chestReady && !_busy;
    final allFolding =
        ready.isNotEmpty && ready.every((a) => _folded.contains(a.id));

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: () => ref.read(achievementRoadsProvider.notifier).reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          StageStepper(
            stages: road.stages,
            currentIndex: road.currentStage,
            selectedIndex: selected,
            onSelect: (i) {
              if (!_busy) setState(() => _selected = i);
            },
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration:
                AppMotion.duration(context, const Duration(milliseconds: 500)),
            switchInCurve: const Cubic(.2, 1, .3, 1),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween(begin: const Offset(.14, 0), end: Offset.zero)
                  .animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: StageCard(
              key: ValueKey('${road.category}-${stage.tier}'),
              stage: stage,
              number: selected + 1,
              count: road.stages.length,
              chestAnchor: _chestAnchor,
              completing: _completingTier == stage.tier,
              chestAway: _chestAway && _completingTier == stage.tier,
              arrived: _arrivedTier == stage.tier,
              nudge: _nudge,
              onOpenChest: canOpen ? () => _openChest(stage.tier) : null,
            ),
          ),
          AnimatedSize(
            duration:
                AppMotion.duration(context, const Duration(milliseconds: 400)),
            alignment: Alignment.topCenter,
            child: ready.isEmpty
                ? const SizedBox(width: double.infinity)
                : AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: allFolding ? 0 : 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          RoadSectionTitle(
                            'READY TO CLAIM',
                            color: kRoadReady,
                            trailing: ready.length > 1
                                ? TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _claim(road, ready),
                                    style: TextButton.styleFrom(
                                        foregroundColor: kRoadReady,
                                        minimumSize: const Size(44, 32)),
                                    child: Text(
                                        ready.length == 2
                                            ? 'Claim both'
                                            : 'Claim all ${ready.length}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          for (final a in ready)
                            Builder(builder: (_) {
                              final (row, coin, gem) = _anchorsFor(a.id);
                              return ReadyRow(
                                key: ValueKey(a.id),
                                a: a,
                                claiming: _claiming.contains(a.id),
                                folded: _folded.contains(a.id),
                                anchor: row,
                                coinAnchor: coin,
                                gemAnchor: gem,
                                onClaim: _busy ? null : () => _claim(road, [a]),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
          ),
          AnimatedSwitcher(
            duration:
                AppMotion.duration(context, const Duration(milliseconds: 500)),
            switchInCurve: const Cubic(.2, 1, .3, 1),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween(begin: const Offset(.14, 0), end: Offset.zero)
                  .animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Column(
              key: ValueKey('lists-${stage.tier}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (inProgress.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  RoadSectionTitle(_arrivedTier == stage.tier
                      ? 'IN PROGRESS · STAGE ${selected + 1}'
                      : 'IN PROGRESS'),
                  const SizedBox(height: 6),
                  for (final a in inProgress)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ProgressRow(a: a),
                    ),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DoneRow(done: done),
                ],
                if (next != null && !next.chestOpened) ...[
                  const SizedBox(height: 12),
                  UpNextRow(stage: next, number: selected + 2),
                ],
                if (road.isComplete) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Road complete — every chest opened.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toast ─────────────────────────────────────────────────────────────────────

class _ToastData {
  final Widget leading;
  final String title;
  final Widget sub;
  final Color border;
  const _ToastData(
      {required this.leading,
      required this.title,
      required this.sub,
      required this.border});

  /// "2 rewards claimed · +600 XP · coins · gems".
  factory _ToastData.claimed(
          AchievementClaimResult r, List<AchievementDto> rows) =>
      _ToastData(
        leading: Container(
          width: 32,
          height: 32,
          decoration:
              const BoxDecoration(shape: BoxShape.circle, color: kRoadDone),
          child: const Icon(Icons.check_rounded,
              size: 18, color: Color(0xFF04130A)),
        ),
        title: r.claimedIds.length == 1
            ? '${rows.first.title} claimed'
            : '${r.claimedIds.length} rewards claimed',
        sub: RewardLine(xp: r.xp, coins: r.coins, gems: r.gems, fontSize: 11.5),
        border: kRoadDone,
      );

  /// "Recovery Slides added to your gear · Stage 3 is now open".
  factory _ToastData.chest(StageChestOpenResult r, String next) {
    final item = r.item;
    return _ToastData(
      leading: item == null
          ? const Icon(Icons.inventory_2_rounded, color: kRoadReady)
          : ItemIconImage(
              itemId: item.id,
              itemName: item.name,
              emojiFallback: item.icon,
              imageUrl: item.inventoryIconUrl,
              size: 34),
      title: item == null
          ? '${r.chestName} opened'
          : '${item.name} added to your gear',
      sub: Text(next,
          style:
              const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      border: AppColors.blue,
    );
  }
}

/// Slides up from the bottom (scToast), stays ~3 s.
class _RoadToast extends StatelessWidget {
  final _ToastData? data;
  const _RoadToast({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    return IgnorePointer(
      ignoring: d == null,
      child: AnimatedSlide(
        offset: d == null ? const Offset(0, 1.6) : Offset.zero,
        duration:
            AppMotion.duration(context, const Duration(milliseconds: 400)),
        curve: d == null ? Curves.easeIn : const Cubic(.2, 1.2, .4, 1),
        child: AnimatedOpacity(
          opacity: d == null ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: d == null
              ? const SizedBox(height: 60)
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2632),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: d.border.withValues(alpha: .5)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 40,
                          offset: Offset(0, 12)),
                    ],
                  ),
                  child: Row(
                    children: [
                      d.leading,
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            d.sub,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
