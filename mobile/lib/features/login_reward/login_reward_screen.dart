import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/widgets/app_icon_image.dart';
import '../../core/widgets/app_toast.dart';
import '../character/providers/character_provider.dart';
import '../quests/models/quest_models.dart';
import 'models/reward_center_models.dart';
import 'providers/login_reward_provider.dart';
import 'services/login_reward_service.dart';

/// Show the rewards bottom sheet. Same presentation pattern as
/// [showStreakDetailSheet] — a modal bottom sheet with a drag handle,
/// not a floating centered dialog.
Future<void> showRewardsSheet(BuildContext context, {bool startWeekly = false}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LoginRewardScreen(startWeekly: startWeekly),
  );
}

class LoginRewardScreen extends ConsumerStatefulWidget {
  final bool startWeekly;

  const LoginRewardScreen({super.key, this.startWeekly = false});

  @override
  ConsumerState<LoginRewardScreen> createState() => _LoginRewardScreenState();
}

class _LoginRewardScreenState extends ConsumerState<LoginRewardScreen> {
  late bool _weekly = widget.startWeekly;
  bool _claiming = false;
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
              center.when(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(RewardCenterData data) {
    final period = _weekly ? data.weekly : data.daily;
    final dailyHasClaimable =
        data.daily.milestones.any((m) => m.isUnlocked && !m.isClaimed);
    final weeklyHasClaimable = data.weekly.milestones
        .any((m) => m.isUnlocked && !m.isClaimed);

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
          height: 280,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: period.tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _TaskRow(task: period.tasks[i]),
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
      final results = await ref
          .read(rewardCenterProvider.notifier)
          .claimAvailableMilestones(_weekly ? 'weekly' : 'daily');
      ref.invalidate(characterProfileProvider);
      if (mounted) AppToast.success(context, _summarize(results));
    } on LoginRewardException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  static String _summarize(List<MilestoneClaimResult> results) {
    final totalXp = results.fold<int>(0, (sum, r) => sum + r.reward.xp);
    final label = results.length == 1
        ? 'Milestone reward claimed!'
        : '${results.length} milestone rewards claimed!';
    return totalXp > 0 ? '$label (+$totalXp XP)' : label;
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
                  color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800)),
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
          const Icon(Icons.schedule_rounded, color: AppColors.textSecondary, size: 14),
          const SizedBox(width: 6),
          const Text(
            'Refresh Time:',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700),
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
  const _PointsTrack({
    required this.period,
    required this.claiming,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        // Icon + point total sit on the same line as the bar, instead of a
        // header row above it — the value lives right under the icon.
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIconImage(AppIcons.dailyPointsBadge, size: 25),
              const SizedBox(height: 1),
              Text('${period.pointsEarned}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              Positioned(
                left: 15,
                right: 15,
                top: 18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: period.pointsEarned / period.pointsMaximum,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF0D141F),
                    valueColor: const AlwaysStoppedAnimation(AppColors.blue),
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

class _MilestoneNode extends StatelessWidget {
  final RewardMilestone milestone;
  final bool claiming;
  final VoidCallback onClaim;
  const _MilestoneNode(
      {required this.milestone, required this.claiming, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final reward = milestone.reward;
    final claimable = milestone.isUnlocked && !milestone.isClaimed;
    final label = _rewardLabel(reward);

    return Semantics(
      button: claimable,
      label: '$label at ${milestone.threshold} points',
      child: InkWell(
        // Tapping any claimable tier claims every reached-but-unclaimed
        // tier for the period, not just this one.
        onTap: claimable && !claiming ? onClaim : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
          child: Column(children: [
            Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                  color: milestone.isClaimed
                      ? AppColors.green.withValues(alpha: .14)
                      : claimable
                          ? AppColors.blue.withValues(alpha: .14)
                          : AppColors.backgroundAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: milestone.isClaimed
                          ? AppColors.green
                          : claimable
                              ? AppColors.blue
                              : AppColors.border,
                      width: 1.5)),
              child: Center(
                  child: claiming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.blue))
                      : milestone.isClaimed
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.green, size: 18)
                          : Opacity(
                              opacity: claimable ? 1 : .45,
                              child: Image.asset(_rewardIcon(reward),
                                  width: 19, height: 19),
                            )),
            ),
            const SizedBox(height: 3),
            Text(
                milestone.isClaimed
                    ? label
                    : claimable
                        ? 'CLAIM'
                        : '${milestone.threshold}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: milestone.isClaimed
                        ? AppColors.green
                        : claimable
                            ? AppColors.blue
                            : AppColors.textMuted,
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
    return AppIcons.itemXpBooster;
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

class _TaskRow extends StatelessWidget {
  final UserQuestProgress task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: task.isCompleted
                ? AppColors.green.withValues(alpha: .07)
                : AppColors.backgroundAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: task.isCompleted
                    ? AppColors.green.withValues(alpha: .35)
                    : AppColors.border)),
        child: Row(children: [
          _RewardTile(
              icon: task.rewardCrystals > 0
                  ? AppIcons.homeGemIcon
                  : AppIcons.homeCoinIcon,
              label:
                  'x${task.rewardCrystals > 0 ? task.rewardCrystals : task.rewardCoins}'),
          const SizedBox(width: 5),
          _PointsTile(label: '+${task.rewardPoints}'),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: task.isCompleted
                            ? const Color(0xFFBDF0CC)
                            : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                        value: task.progress,
                        minHeight: 5,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation(task.isCompleted
                            ? AppColors.green
                            : AppColors.blue))),
                const SizedBox(height: 3),
                Text(
                    '${_value(task.currentValue, task.targetUnit)} / ${_value(task.targetValue, task.targetUnit)} ${task.targetUnit}',
                    style: TextStyle(
                        color: task.isCompleted
                            ? const Color(0xFF8FD6A4)
                            : AppColors.textMuted,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700)),
              ])),
          if (task.isCompleted) ...[
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: .18),
                border: Border.all(color: AppColors.green),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.green, size: 12),
            ),
          ],
        ]),
      );

  static String _value(double value, String unit) =>
      unit == 'km' ? value.toStringAsFixed(1) : value.toInt().toString();
}

class _RewardTile extends StatelessWidget {
  final String icon;
  final String label;
  const _RewardTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        width: 31,
        height: 35,
        decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, width: 14, height: 14),
            const SizedBox(height: 1),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 7,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

// Same icon+amount pattern as _RewardTile — every task row shows both what
// currency it grants and how many points it's worth toward the milestone
// track, not just a bare number.
class _PointsTile extends StatelessWidget {
  final String label;
  const _PointsTile({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        width: 31,
        height: 35,
        decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.blue.withValues(alpha: .3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIconImage(AppIcons.dailyPointsBadge, size: 14),
            const SizedBox(height: 1),
            Text(label,
                style: const TextStyle(
                    color: AppColors.blue, fontSize: 7, fontWeight: FontWeight.w800)),
          ],
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
                    child:
                        const Text('Try again', style: TextStyle(fontSize: 14)))),
          ]),
        ),
      );
}
