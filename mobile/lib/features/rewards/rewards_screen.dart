import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/motion/reward_fx.dart';
import '../../core/widgets/app_icon_image.dart';
import '../../core/widgets/app_toast.dart';
import '../character/providers/character_provider.dart';
import '../quests/models/quest_models.dart';
import 'models/rewards_models.dart';
import 'providers/rewards_provider.dart';
import 'services/rewards_service.dart';
import 'widgets/task_reward_popup.dart';

List<UserQuestProgress> orderRewardTasksForDisplay(
    Iterable<UserQuestProgress> tasks) {
  final snapshot = tasks.toList(growable: false);
  return <UserQuestProgress>[
    ...snapshot.where((task) => task.isCompleted && !task.rewardClaimed),
    ...snapshot.where((task) => !task.isCompleted),
    ...snapshot.where((task) => task.isCompleted && task.rewardClaimed),
  ];
}

/// Show the rewards bottom sheet. Same presentation pattern as
/// [showStreakDetailSheet] — a modal bottom sheet with a drag handle,
/// not a floating centered dialog.
Future<void> showRewardsSheet(BuildContext context,
    {bool startWeekly = false}) {
  return showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RewardsScreen(startWeekly: startWeekly),
  );
}

class RewardsScreen extends ConsumerStatefulWidget {
  final bool startWeekly;

  const RewardsScreen({super.key, this.startWeekly = false});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  late bool _weekly = widget.startWeekly;
  bool _claiming = false;
  bool _claimingTasks = false;

  // Claim-all "vacuum": reward tiles fly into the points badge.
  final _badge = FxAnchor();
  final _badgeHits = ValueNotifier<int>(0);
  final Map<String, (FxAnchor, FxAnchor)> _tileAnchors = {};
  (FxAnchor, FxAnchor) _anchorsFor(String taskId) =>
      _tileAnchors.putIfAbsent(taskId, () => (FxAnchor(), FxAnchor()));

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _badgeHits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = ref.watch(rewardCenterProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3a4a5a),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppAnimatedState(
                stateKey: center.runtimeType,
                child: center.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.blue, strokeWidth: 2),
                    ),
                  ),
                  error: (error, _) => _ErrorState(
                    onRetry: () =>
                        ref.read(rewardCenterProvider.notifier).refresh(),
                  ),
                  data: _buildBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(RewardCenterData data) {
    final period = _weekly ? data.weekly : data.daily;
    // Ready-to-claim tasks are the primary action, active tasks stay in the
    // middle, and already-collected tasks remain at the bottom. Preserve the
    // API order inside each group explicitly.
    final orderedTasks = orderRewardTasksForDisplay(period.tasks);
    final dailyHasClaimable =
        data.daily.milestones.any((m) => m.isUnlocked && !m.isClaimed) ||
            data.daily.tasks.any((t) => t.isCompleted && !t.rewardClaimed);
    final weeklyHasClaimable =
        data.weekly.milestones.any((m) => m.isUnlocked && !m.isClaimed) ||
            data.weekly.tasks.any((t) => t.isCompleted && !t.rewardClaimed);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PeriodToggle(
          weekly: _weekly,
          showDailyBadge: dailyHasClaimable,
          showWeeklyBadge: weeklyHasClaimable,
          onChanged: (value) => setState(() => _weekly = value),
        ),
        const SizedBox(height: 12),
        _Countdown(resetAt: period.resetAtUtc),
        const SizedBox(height: 12),
        _PointsTrack(
          period: period,
          claiming: _claiming,
          onClaim: _claimAvailable,
          badge: _badge,
          badgeHits: _badgeHits,
        ),
        const SizedBox(height: 14),
        Row(children: [
          Text(
            '${period.tasks.length} TASKS',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(child: Divider(color: AppColors.border, height: 1)),
        ]),
        const SizedBox(height: 8),
        // Fixed height ≈ 5 rows — the rest scrolls in its own area,
        // independent of the sheet's own drag/scroll.
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * .38)
              .clamp(220.0, 360.0)
              .toDouble(),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: orderedTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _TaskRow(
              task: orderedTasks[i],
              claiming: _claimingTasks,
              onClaim: _claimAvailableTasks,
              tileAnchors: _anchorsFor(orderedTasks[i].id),
            ),
          ),
        ),
      ],
    );
  }

  // Tapping any claimable milestone collects every reached-but-unclaimed
  // milestone for the period in one action — same "claim available" pattern
  // as the season track, rather than requiring one tap per tier.
  Future<void> _claimAvailable() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      await ref
          .read(rewardCenterProvider.notifier)
          .claimAvailableMilestones(_weekly ? 'weekly' : 'daily');
      ref.invalidate(characterProfileProvider);
    } on RewardsException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _claimAvailableTasks() async {
    if (_claimingTasks) return;
    setState(() => _claimingTasks = true);
    // Snapshot what's being claimed — the rows re-render as claimed once
    // the request lands.
    final data = ref.read(rewardCenterProvider).valueOrNull;
    final period = data == null ? null : (_weekly ? data.weekly : data.daily);
    final claimable = [
      for (final t in period?.tasks ?? const <UserQuestProgress>[])
        if (t.isCompleted && !t.rewardClaimed) t,
    ];
    final points = claimable.fold<int>(0, (sum, t) => sum + t.rewardPoints);
    try {
      final result = await ref
          .read(rewardCenterProvider.notifier)
          .claimAvailableTaskRewards(_weekly ? 'weekly' : 'daily');
      ref.invalidate(characterProfileProvider);
      if (!mounted) return;
      if (RewardFx.enabled(context) && claimable.isNotEmpty) {
        final items = [
          if (result.coins > 0)
            TaskRewardItem(
                asset: AppIcons.homeCoinIcon,
                label: '×${result.coins}',
                color: AppColors.orange),
          if (result.crystals > 0)
            TaskRewardItem(
                asset: AppIcons.homeGemIcon,
                label: '×${result.crystals}',
                color: AppColors.purple),
          if (points > 0)
            TaskRewardItem(
                asset: AppIcons.dailyPointsBadge,
                label: '+$points',
                color: AppColors.blue),
        ];
        final subtitle = claimable.length == 1
            ? claimable.first.description
            : '${claimable.length} tasks complete';
        // Chest burst popup; when it closes, the rewards fly on into the
        // points badge. Not awaited so the claim button frees up at once.
        unawaited(showTaskRewardPopup(context, items: items, subtitle: subtitle)
            .then((landed) {
          if (mounted && landed.isNotEmpty) unawaited(_vacuum(landed));
        }));
      } else {
        final rewards = <String>[
          if (result.coins > 0) '${result.coins} coins',
          if (result.crystals > 0) '${result.crystals} crystals',
        ];
        final suffix = rewards.isEmpty ? '' : ' · ${rewards.join(', ')}';
        AppToast.success(
          context,
          '${result.tasksClaimed} task${result.tasksClaimed == 1 ? '' : 's'} claimed$suffix',
        );
      }
    } on RewardsException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } finally {
      if (mounted) setState(() => _claimingTasks = false);
    }
  }

  /// Every claimed reward spirals into the points badge, which squashes on
  /// each arrival, then a shockwave.
  Future<void> _vacuum(List<(Offset, String)> sources) async {
    final target = _badge.center;
    if (target == null) return;
    final flights = <Future<void>>[];
    for (final (i, (from, asset)) in sources.indexed) {
      flights.add(RewardFx.fly(
        context,
        child: AppIconImage(asset, size: 22),
        from: from,
        to: target,
        lift: -40,
        sideways: (i.isOdd ? 1 : -1) * 90,
        endScale: .35,
        spinTurns: 1,
        duration: const Duration(milliseconds: 700),
        delay: Duration(milliseconds: i * 80),
        curve: const Cubic(.6, 0, .9, .7),
      ).then((_) => _badgeHits.value++));
    }
    await Future.wait(flights);
    if (!mounted) return;
    RewardFx.ring(context, target, AppColors.blue, maxRadius: 52);
    RewardFx.burst(context, target, const Color(0xFF7DB8FF),
        count: 12, distance: 44);
  }
}

// ── Segmented Daily/Weekly toggle — takes the place of a tab bar; a bottom
// sheet's own bottom edge is for the drag/dismiss gesture, not persistent
// nav, so the switcher sits under the handle instead. Each badge is real,
// not decorative: it only shows when that period actually has an unclaimed
// milestone. ────────────────────────────────────────────────────────────
class _PeriodToggle extends StatelessWidget {
  final bool weekly;
  final bool showDailyBadge;
  final bool showWeeklyBadge;
  final ValueChanged<bool> onChanged;
  const _PeriodToggle({
    required this.weekly,
    required this.showDailyBadge,
    required this.showWeeklyBadge,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.backgroundAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Expanded(
            child: _ToggleButton(
              label: 'Daily',
              selected: !weekly,
              showBadge: showDailyBadge,
              badgeOnLeft: true,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Weekly',
              selected: weekly,
              showBadge: showWeeklyBadge,
              badgeOnLeft: false,
              onTap: () => onChanged(true),
            ),
          ),
        ]),
      );
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool showBadge;
  final bool badgeOnLeft;
  final VoidCallback onTap;
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.showBadge,
    required this.badgeOnLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    top: -5,
                    left: badgeOnLeft ? 2 : null,
                    right: badgeOnLeft ? null : 2,
                    child: const _Badge(),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge();
  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.red,
          border: Border.all(color: AppColors.surface, width: 1.5),
        ),
        child: const Center(
          child: Text('!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800)),
        ),
      );
}

class _Countdown extends StatelessWidget {
  final DateTime resetAt;
  const _Countdown({required this.resetAt});

  @override
  Widget build(BuildContext context) {
    final remaining = resetAt.toUtc().difference(DateTime.now().toUtc());
    final value = remaining.isNegative
        ? 'Resetting…'
        : '${remaining.inDays > 0 ? '${remaining.inDays}d ' : ''}${remaining.inHours.remainder(24)}h ${remaining.inMinutes.remainder(60)}m';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule_rounded,
              color: AppColors.textSecondary, size: 14),
          const SizedBox(width: 6),
          const Text(
            'Resets in:',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsTrack extends StatelessWidget {
  final TaskRewardPeriod period;
  final bool claiming;
  final VoidCallback onClaim;
  final FxAnchor badge;
  final ValueListenable<int> badgeHits;
  const _PointsTrack({
    required this.period,
    required this.claiming,
    required this.onClaim,
    required this.badge,
    required this.badgeHits,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SquashOnHit(
                hits: badgeHits,
                child: FxAnchorTarget(
                  anchor: badge,
                  child:
                      const AppIconImage(AppIcons.dailyPointsBadge, size: 25),
                ),
              ),
              const SizedBox(height: 1),
              TweenAnimationBuilder<double>(
                tween: Tween(end: period.pointsEarned.toDouble()),
                duration: AppMotion.duration(
                    context, const Duration(milliseconds: 600)),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text('${v.round()}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // The points track intentionally runs through the milestone
                  // rewards. It is painted first so reward icons/checks stay on
                  // top and remain readable.
                  Positioned(
                    left: 15,
                    right: 15,
                    top: 18,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            end: period.pointsMaximum <= 0
                                ? 0
                                : (period.pointsEarned / period.pointsMaximum)
                                    .clamp(0.0, 1.0)),
                        duration: AppMotion.duration(
                            context, const Duration(milliseconds: 700)),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: const Color(0xFF0D141F),
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.blue)),
                      ),
                    ),
                  ),
                  Row(children: [
                    for (final milestone in period.milestones)
                      Expanded(
                          child: _MilestoneNode(
                              milestone: milestone,
                              // A claim-available sweep claims every reached
                              // tier at once, so every still-claimable node
                              // busies up together, not just the tapped one.
                              claiming: claiming &&
                                  milestone.isUnlocked &&
                                  !milestone.isClaimed,
                              onClaim: onClaim))
                  ]),
                ]),
          ),
        ]),
      );
}

/// One reward on the points track.
///
/// A ready (unlocked, unclaimed) milestone is drawn in reward gold and plays
/// "gift shake + shine" on a loop: every few seconds it wiggles like a
/// wrapped present, a shine sweeps across it and three sparks twinkle
/// around it. Claiming pops it with a ring and a burst.
class _MilestoneNode extends StatefulWidget {
  final RewardMilestone milestone;
  final bool claiming;
  final VoidCallback onClaim;
  const _MilestoneNode(
      {required this.milestone, required this.claiming, required this.onClaim});

  @override
  State<_MilestoneNode> createState() => _MilestoneNodeState();
}

class _MilestoneNodeState extends State<_MilestoneNode>
    with TickerProviderStateMixin {
  // Loop timeline (fractions of 1.6 s): wiggle .35–.65, shine .65–.9,
  // sparks .6–.85. The short still beat keeps it reading as "waiting".
  late final AnimationController _loop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  final _anchor = FxAnchor();

  RewardMilestone get milestone => widget.milestone;
  bool get claiming => widget.claiming;
  VoidCallback get onClaim => widget.onClaim;

  bool get _claimable => milestone.isUnlocked && !milestone.isClaimed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  @override
  void didUpdateWidget(_MilestoneNode old) {
    super.didUpdateWidget(old);
    _syncLoop();
    final wasReady = old.milestone.isUnlocked && !old.milestone.isClaimed;
    if (wasReady && milestone.isClaimed && RewardFx.enabled(context)) {
      _pop.forward(from: 0);
      final c = _anchor.center;
      if (c != null) {
        RewardFx.ring(context, c, AppColors.orange, maxRadius: 46);
        RewardFx.burst(context, c, const Color(0xFFFFD27A),
            count: 12, distance: 44, size: 5);
      }
    }
  }

  void _syncLoop() {
    final run = _claimable && !claiming && AppMotion.isFull(context);
    if (run && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!run && _loop.isAnimating) {
      _loop
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _pop.dispose();
    super.dispose();
  }

  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// Wiggle angle (radians) at loop time [t].
  static double _wiggle(double t) {
    if (t < .35 || t > .65) return 0;
    const keys = [0.0, -11.0, 9.0, -6.0, 4.0, 0.0];
    final p = _seg(t, .35, .65) * (keys.length - 1);
    final i = p.floor().clamp(0, keys.length - 2);
    final deg = keys[i] + (keys[i + 1] - keys[i]) * (p - i);
    return deg * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final reward = milestone.reward;
    final claimable = _claimable;
    final label = _rewardLabel(reward);

    return Semantics(
      button: claimable,
      label: '$label at ${milestone.threshold} points',
      // Plain tap target: no InkWell, so no hover/focus/splash highlight is
      // painted over the gold ready state. A ready reward only claims
      // (claiming sweeps every reached tier for the period); anything else
      // opens the reward info.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: claimable
            ? (claiming ? null : onClaim)
            : () => _showRewardInfo(context, _milestoneRewardInfo(reward)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
          child: Column(children: [
            FxAnchorTarget(
              anchor: _anchor,
              child: AnimatedBuilder(
                animation: Listenable.merge([_loop, _pop]),
                builder: (context, box) {
                  final t = _loop.isAnimating ? _loop.value : 0.0;
                  final shake = _wiggle(t);
                  final grow = t >= .35 && t <= .65
                      ? 1 + .06 * math.sin(_seg(t, .35, .65) * math.pi)
                      : 1.0;
                  final pop = _pop.isAnimating
                      ? 1 + .25 * math.sin(_pop.value * math.pi)
                      : 1.0;
                  final shine = _seg(t, .65, .9);
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform(
                        alignment: const Alignment(0, .8),
                        transform: Matrix4.identity()
                          ..rotateZ(shake)
                          ..scale(grow * pop, grow * pop),
                        child: Stack(children: [
                          box!,
                          if (shine > 0 && shine < 1)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Align(
                                  alignment: Alignment(-1.6 + 3.2 * shine, 0),
                                  child: Transform(
                                    transform: Matrix4.skewX(-.35),
                                    child: Container(
                                      width: 12,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Color(0x00FFFFFF),
                                          Color(0xD9FFFFFF),
                                          Color(0x00FFFFFF),
                                        ]),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ]),
                      ),
                      for (final (i, o) in const [
                        Offset(-21, -19),
                        Offset(23, -11),
                        Offset(5, 24),
                      ].indexed)
                        _Spark(offset: o, t: t, delay: i * .04),
                    ],
                  );
                },
                child: Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                      color: milestone.isClaimed
                          ? Color.alphaBlend(
                              AppColors.green.withValues(alpha: .14),
                              AppColors.surfaceElevated,
                            )
                          : claimable
                              ? Color.alphaBlend(
                                  AppColors.orange.withValues(alpha: .14),
                                  AppColors.surfaceElevated,
                                )
                              : AppColors.backgroundAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: milestone.isClaimed
                              ? AppColors.green
                              : claimable
                                  ? AppColors.orange
                                  : AppColors.border,
                          width: 1.5),
                      boxShadow: claimable
                          ? [
                              BoxShadow(
                                  color:
                                      AppColors.orange.withValues(alpha: .35),
                                  blurRadius: 10)
                            ]
                          : null),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (claiming)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.blue),
                        )
                      else
                        Opacity(
                          opacity: milestone.isClaimed || claimable ? 1 : .45,
                          child: AppIconImage(
                            _rewardIcon(reward),
                            size: 24,
                            visualScale:
                                _rewardIcon(reward) == AppIcons.rewardXpCrystals
                                    ? 2.65
                                    : 1.25,
                          ),
                        ),
                      Positioned(
                        left: 2,
                        right: 2,
                        bottom: 1,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 3),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text('${milestone.threshold}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }

  // Real icon per reward type — fixes the old logic, which only ever
  // branched on crystals then coins then a generic star, so a milestone
  // that grants a Streak Shield (day 100 / week 200) never showed one.
  static String _rewardIcon(MilestoneReward reward) {
    if (reward.shields > 0) return AppIcons.rewardStreakShield;
    if (reward.crystals > 0) return AppIcons.homeGemIcon;
    if (reward.coins > 0) return AppIcons.homeCoinIcon;
    return AppIcons.rewardXpCrystals;
  }

  // Composite label — a milestone can grant more than one reward type
  // (e.g. 150 XP *and* a shield); the old ternary chain could only ever
  // show one.
  static String _rewardLabel(MilestoneReward reward) {
    final bits = <String>[];
    if (reward.coins > 0) bits.add('x${reward.coins}');
    if (reward.crystals > 0) bits.add('x${reward.crystals}');
    if (reward.xp > 0) bits.add('${reward.xp} XP');
    if (reward.shields > 0) bits.add('🛡');
    return bits.join(' ');
  }
}

/// Squashes its child (scaleX up, scaleY down) every time [hits] ticks.
class _SquashOnHit extends StatefulWidget {
  final ValueListenable<int> hits;
  final Widget child;
  const _SquashOnHit({required this.hits, required this.child});

  @override
  State<_SquashOnHit> createState() => _SquashOnHitState();
}

class _SquashOnHitState extends State<_SquashOnHit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 180));

  @override
  void initState() {
    super.initState();
    widget.hits.addListener(_hit);
  }

  void _hit() => _c.forward(from: 0);

  @override
  void dispose() {
    widget.hits.removeListener(_hit);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final k = math.sin(_c.value * math.pi);
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(1 + .25 * k, 1 - .18 * k, 1),
            child: child,
          );
        },
        child: widget.child,
      );
}

/// Daily/weekly task (quest) row. Progress changes animate with a bright
/// leading edge; finishing a task pulses the row green and floats the
/// points reward; claiming draws the check mark in.
class _TaskRow extends StatefulWidget {
  final UserQuestProgress task;
  final bool claiming;
  final VoidCallback onClaim;
  final (FxAnchor, FxAnchor) tileAnchors;
  const _TaskRow({
    required this.task,
    required this.claiming,
    required this.onClaim,
    required this.tileAnchors,
  });

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> with TickerProviderStateMixin {
  late final AnimationController _done = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..addListener(() => setState(() {}));

  // "The bar is the button": a finished, unclaimed task's progress bar turns
  // into moving stripes that say TAP TO CLAIM. Drives the stripe scroll and,
  // while the claim request runs, a light sweep along the bar.
  late final AnimationController _stripes = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  bool get _ready => task.isCompleted && !task.rewardClaimed;

  void _syncStripes() {
    final run = _ready && AppMotion.isFull(context);
    if (run && !_stripes.isAnimating) {
      _stripes.repeat();
    } else if (!run && _stripes.isAnimating) {
      _stripes.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncStripes();
  }

  UserQuestProgress get task => widget.task;
  bool get claiming => widget.claiming;
  VoidCallback get onClaim => widget.onClaim;

  @override
  void didUpdateWidget(_TaskRow old) {
    super.didUpdateWidget(old);
    _syncStripes();
    if (old.task.id != task.id) return;
    if (!old.task.isCompleted &&
        task.isCompleted &&
        RewardFx.enabled(context)) {
      // Wait for the fill to reach the end, then celebrate.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        _done.forward(from: 0);
        final p = widget.tileAnchors.$2.center;
        if (p != null) {
          RewardFx.floatText(
              context, p, '+${task.rewardPoints} pts', const Color(0xFF7DB8FF),
              rise: 40);
        }
      });
    }
  }

  @override
  void dispose() {
    _done.dispose();
    _stripes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claimed = task.rewardClaimed;
    final ready = _ready;
    final pulse = _done.isAnimating
        ? (_done.value < .4 ? _done.value / .4 : 1 - (_done.value - .4) / .6)
        : 0.0;

    final content = Row(children: [
      FxAnchorTarget(
        anchor: widget.tileAnchors.$1,
        child: _RewardTile(
            icon: task.rewardCrystals > 0
                ? AppIcons.homeGemIcon
                : AppIcons.homeCoinIcon,
            label:
                'x${task.rewardCrystals > 0 ? task.rewardCrystals : task.rewardCoins}',
            onTap: () => _showRewardInfo(
                  context,
                  task.rewardCrystals > 0
                      ? _crystalRewardInfo
                      : _coinRewardInfo,
                )),
      ),
      const SizedBox(width: 5),
      FxAnchorTarget(
        anchor: widget.tileAnchors.$2,
        child: _PointsTile(
          label: '+${task.rewardPoints}',
          onTap: () => _showRewardInfo(context, _dailyPointsRewardInfo),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: task.isCompleted
                        ? const Color(0xFFBDF0CC)
                        : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (ready)
              _ClaimBar(stripes: _stripes, claiming: claiming)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 17,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: task.progress.clamp(0.0, 1.0)),
                        duration: AppMotion.duration(
                            context, const Duration(milliseconds: 700)),
                        curve: const Cubic(.2, .8, .2, 1),
                        builder: (_, v, __) {
                          final moving = (v - task.progress).abs() > .002;
                          return Stack(fit: StackFit.expand, children: [
                            LinearProgressIndicator(
                              value: v,
                              minHeight: 17,
                              backgroundColor: AppColors.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation(
                                  task.isCompleted && !moving
                                      ? AppColors.green
                                      : AppColors.blue),
                            ),
                            // Bright leading edge while the fill moves.
                            if (moving)
                              Align(
                                alignment: Alignment(v * 2 - 1, 0),
                                child: Container(
                                  width: 12,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Color(0x00FFFFFF),
                                      Colors.white,
                                    ]),
                                  ),
                                ),
                              ),
                          ]);
                        },
                      ),
                      Center(
                        child: Text(
                          '${_value(task.currentValue, task.targetUnit)} / ${_value(task.targetValue, task.targetUnit)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ])),
      if (claimed)
        // Reserve room for the completion check painted above the dim layer.
        const SizedBox(width: 30),
    ]);

    final row = Container(
      decoration: BoxDecoration(
          color: task.isCompleted && !claimed
              ? AppColors.green.withValues(alpha: .07)
              : AppColors.backgroundAlt,
          boxShadow: pulse > 0
              ? [
                  BoxShadow(
                      color: AppColors.green.withValues(alpha: .45 * pulse),
                      blurRadius: 22)
                ]
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: task.isCompleted && !claimed
                  ? AppColors.green.withValues(alpha: .35)
                  : AppColors.border)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: content,
            ),
            if (claimed)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: const Color(0xFF8C949E).withValues(alpha: .28),
                  ),
                ),
              ),
            if (claimed)
              Positioned(
                right: 14,
                child: DrawnCheck(shown: claimed, size: 20),
              ),
          ],
        ),
      ),
    );
    if (!ready) return row;
    return Semantics(
      button: true,
      label: 'Claim ${task.description} reward',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: claiming ? null : onClaim,
        child: row,
      ),
    );
  }

  static String _value(double value, String unit) =>
      unit == 'km' ? value.toStringAsFixed(1) : value.toInt().toString();
}

class _RewardTile extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _RewardTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Reward information',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 38,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.border)),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: AppIconImage(icon, size: 22),
                  ),
                ),
                Positioned(
                  right: 3,
                  bottom: 2,
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 8,
                          height: 1,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      );
}

// Same icon+amount pattern as _RewardTile — every task row shows both what
// currency it grants and how many points it's worth toward the milestone
// track, not just a bare number.
class _PointsTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PointsTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Daily Points information',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 38,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(7),
                border:
                    Border.all(color: AppColors.blue.withValues(alpha: .3))),
            child: Stack(
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: AppIconImage(AppIcons.dailyPointsBadge, size: 22),
                  ),
                ),
                Positioned(
                  right: 3,
                  bottom: 2,
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          height: 1,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RewardInfo {
  final String name;
  final String icon;
  final String description;
  final String destination;

  const _RewardInfo({
    required this.name,
    required this.icon,
    required this.description,
    required this.destination,
  });
}

const _coinRewardInfo = _RewardInfo(
  name: 'Coins',
  icon: AppIcons.homeCoinIcon,
  description: 'Universal currency used to buy items and useful upgrades.',
  destination: 'Shop',
);

const _crystalRewardInfo = _RewardInfo(
  name: 'Crystals',
  icon: AppIcons.homeGemIcon,
  description: 'A rare currency used to unlock and improve powerful talents.',
  destination: 'Talents',
);

const _dailyPointsRewardInfo = _RewardInfo(
  name: 'Daily Points',
  icon: AppIcons.dailyPointsBadge,
  description:
      'Earned from daily tasks. Reach the marked totals to unlock milestone rewards.',
  destination: 'Daily reward track',
);

const _xpRewardInfo = _RewardInfo(
  name: 'Experience',
  icon: AppIcons.rewardXpCrystals,
  description: 'Raises your character level and unlocks new progression.',
  destination: 'Character progression',
);

const _shieldRewardInfo = _RewardInfo(
  name: 'Streak Shield',
  icon: AppIcons.rewardStreakShield,
  description: 'Protects an active streak when you miss an eligible day.',
  destination: 'Streak protection',
);

_RewardInfo _milestoneRewardInfo(MilestoneReward reward) {
  if (reward.shields > 0) return _shieldRewardInfo;
  if (reward.crystals > 0) return _crystalRewardInfo;
  if (reward.coins > 0) return _coinRewardInfo;
  return _xpRewardInfo;
}

Future<void> _showRewardInfo(BuildContext context, _RewardInfo info) {
  return showAppDialog<void>(
    context: context,
    barrierLabel: 'Dismiss ${info.name} information',
    builder: (_) => Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.blue, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: .22),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue.withValues(alpha: .38),
                        AppColors.surfaceElevated,
                      ],
                    ),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.blue, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.blue.withValues(alpha: .7),
                              width: 2),
                        ),
                        child: AppIconImage(
                          info.icon,
                          size: 50,
                          visualScale: info.icon == AppIcons.rewardXpCrystals
                              ? 2.25
                              : 1.12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: .25),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'REWARD',
                                style: TextStyle(
                                  color: Color(0xFFAED6FF),
                                  fontSize: 9,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Text(
                    info.description,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'USED IN',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            info.destination,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            const Text('Rewards could not be loaded',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
                height: 48,
                child: FilledButton(
                    onPressed: onRetry,
                    child: const Text('Try again',
                        style: TextStyle(fontSize: 14)))),
          ]),
        ),
      );
}

/// Four-point sparkle that twinkles near the end of the milestone loop.
class _Spark extends StatelessWidget {
  final Offset offset;
  final double t;
  final double delay;
  const _Spark({required this.offset, required this.t, required this.delay});

  @override
  Widget build(BuildContext context) {
    final p = ((t - .6 - delay) / .25).clamp(0.0, 1.0);
    if (p <= 0 || p >= 1) return const SizedBox.shrink();
    final k = p < .5 ? p / .5 : 1 - (p - .5) / .5;
    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: k,
        child: Transform.scale(
          scale: .3 + .9 * k,
          child: const Icon(Icons.auto_awesome,
              size: 10, color: Color(0xFFFFE9A8)),
        ),
      ),
    );
  }
}

/// Progress bar of a finished task, turned into its own claim button:
/// taller, green, with diagonal stripes scrolling and a TAP TO CLAIM label.
/// While the claim request runs a bright sweep loops along it.
class _ClaimBar extends StatelessWidget {
  final Animation<double> stripes;
  final bool claiming;
  const _ClaimBar({required this.stripes, required this.claiming});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
              color: AppColors.green.withValues(alpha: .45), blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: AnimatedBuilder(
          animation: stripes,
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _StripesPainter(stripes.value)),
              if (claiming)
                Align(
                  alignment: Alignment(-1.4 + 2.8 * stripes.value, 0),
                  child: Container(
                    width: 60,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Color(0x00FFFFFF),
                        Color(0xCCFFFFFF),
                        Color(0x00FFFFFF),
                      ]),
                    ),
                  ),
                ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIconImage(AppIcons.homeCoinIcon, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      claiming ? 'CLAIMING…' : 'TAP TO CLAIM',
                      style: const TextStyle(
                        color: Color(0xFF04140A),
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  final double phase;
  _StripesPainter(this.phase);

  static const _period = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.green);
    final light = Paint()..color = const Color(0xFF19D964);
    final shift = phase * _period;
    for (var x = -size.height - _period + shift;
        x < size.width + size.height;
        x += _period) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + _period / 2, size.height)
          ..lineTo(x + _period / 2 + size.height, 0)
          ..lineTo(x + size.height, 0)
          ..close(),
        light,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => old.phase != phase;
}
