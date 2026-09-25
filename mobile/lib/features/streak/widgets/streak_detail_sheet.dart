import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/widgets/app_toast.dart';
import '../../character/providers/character_provider.dart';
import '../../home/providers/adventure_hub_status_provider.dart';
import '../../talents/providers/talents_provider.dart';
import '../models/streak_models.dart';
import '../providers/streak_provider.dart';
import '../services/streak_service.dart';

/// Show the streak detail bottom sheet. Reused from the home streak strip,
/// the home header flame chip, and the profile 🔥 Streak tile.
Future<void> showStreakDetailSheet(BuildContext context) {
  return showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const StreakDetailSheet(),
  );
}

/// Bottom sheet with:
/// 1. Keep-alive hero (deadline countdown / "safe today" / "start today")
/// 2. Next milestone row
/// 3. Shields section + Use Shield CTA (closes LL-033)
/// 4. Footer stats (total days active + last activity)
class StreakDetailSheet extends ConsumerStatefulWidget {
  const StreakDetailSheet({super.key});

  @override
  ConsumerState<StreakDetailSheet> createState() => _StreakDetailSheetState();
}

class _StreakDetailSheetState extends ConsumerState<StreakDetailSheet> {
  Timer? _countdownTick;
  bool _shieldBusy = false;
  bool _rewardBusy = false;

  @override
  void initState() {
    super.initState();
    // Once a minute is enough for the "Xh Ym left" text. Timer fires setState
    // which re-reads DateTime.now() and re-renders the keep-alive card.
    _countdownTick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(streakProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                streakAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.orange, strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Failed to load streak',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () =>
                              ref.read(streakProvider.notifier).refresh(),
                          child: const Text('Retry',
                              style: TextStyle(color: AppColors.blue)),
                        ),
                      ],
                    ),
                  ),
                  data: (streak) => _Body(
                    streak: streak,
                    shieldBusy: _shieldBusy,
                    rewardBusy: _rewardBusy,
                    onUseShield: () => _handleUseShield(streak),
                    onClaimReward: _handleClaimReward,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUseShield(StreakData streak) async {
    if (_shieldBusy) return;
    setState(() => _shieldBusy = true);
    try {
      final result = await ref.read(streakProvider.notifier).useShield();
      if (!mounted) return;
      if (result.success) {
        AppToast.success(context, result.message);
      } else {
        AppToast.error(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to use shield: $e');
    } finally {
      if (mounted) setState(() => _shieldBusy = false);
    }
  }

  Future<void> _handleClaimReward() async {
    if (_rewardBusy) return;
    setState(() => _rewardBusy = true);
    try {
      final result = await ref.read(streakProvider.notifier).claimReward();
      ref.invalidate(characterProfileProvider);
      ref.invalidate(talentsProvider);
      ref.invalidate(adventureHubSignalsProvider);
      if (mounted) {
        AppToast.success(context, '+${result.coinsClaimed} coins claimed!');
      }
    } on StreakException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } finally {
      if (mounted) setState(() => _rewardBusy = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body (data-loaded)
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.streak,
    required this.shieldBusy,
    required this.rewardBusy,
    required this.onUseShield,
    required this.onClaimReward,
  });

  final StreakData streak;
  final bool shieldBusy;
  final bool rewardBusy;
  final VoidCallback onUseShield;
  final VoidCallback onClaimReward;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(current: streak.current, longest: streak.longest),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration:
              AppMotion.duration(context, const Duration(milliseconds: 300)),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
                scale: Tween(begin: .97, end: 1.0).animate(a), child: child),
          ),
          child: _KeepAliveCard(
            key: ValueKey(
                '${streak.current}-${streak.lastActivityDate?.toLocal().day}'),
            streak: streak,
          ),
        ),
        const SizedBox(height: 14),
        _DailyRewardCard(
          streak: streak,
          busy: rewardBusy,
          onClaim: onClaimReward,
        ),
        const SizedBox(height: 14),
        _MilestoneRow(current: streak.current),
        const SizedBox(height: 14),
        _ShieldsCard(
          streak: streak,
          busy: shieldBusy,
          onUseShield: onUseShield,
        ),
        const SizedBox(height: 18),
        _FooterStats(
          totalDaysActive: streak.totalDaysActive,
          lastActivityDate: streak.lastActivityDate,
        ),
      ],
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({
    required this.streak,
    required this.busy,
    required this.onClaim,
  });

  final StreakData streak;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final ready = streak.canClaimDailyReward && streak.pendingRewardCoins > 0;
    final nextDay = streak.current + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: ready ? 0.11 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: ready ? 0.55 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🪙', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'DAILY STREAK REWARD',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ready
                ? '${streak.pendingRewardCoins} coins ready to collect'
                : 'Complete streak day $nextDay to earn ${streak.nextRewardCoins} coins.',
            style: TextStyle(
              color: ready ? AppColors.orange : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (ready) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Claim Reward',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — 🔥 icon + title + subtitle
// ─────────────────────────────────────────────────────────────────────────────

/// Streak header. When the day count rises the fire box ignites (flash,
/// scale, a flame that rises out of it and a spray of embers) and the day
/// count flips like a calendar page.
class _Header extends StatefulWidget {
  const _Header({required this.current, required this.longest});

  final int current;
  final int longest;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with SingleTickerProviderStateMixin {
  late final AnimationController _ignite = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..addListener(() => setState(() {}));
  final _boxKey = GlobalKey();

  @override
  void didUpdateWidget(_Header old) {
    super.didUpdateWidget(old);
    if (widget.current <= old.current || !RewardFx.enabled(context)) return;
    _ignite.forward(from: 0);
    final c = RewardFx.centerOf(_boxKey);
    if (c == null) return;
    RewardFx.run(
      context,
      duration: const Duration(milliseconds: 1000),
      builder: (t, origin) {
        final inT = (t / .45).clamp(0.0, 1.0);
        final p = c - origin + Offset(0, 6 - 46 * Curves.easeOut.transform(t));
        return Positioned(
          left: p.dx - 20,
          top: p.dy - 20,
          child: Opacity(
            opacity: t < .45 ? inT : 1 - (t - .45) / .55,
            child: Transform.scale(
              scale: .2 + 1.1 * Curves.easeOutBack.transform(inT),
              child: const AppIconImage(AppIcons.rewardStreakFire, size: 40),
            ),
          ),
        );
      },
    );
    RewardFx.burst(context, c, const Color(0xFFFFB347),
        count: 10, distance: 44, size: 5);
  }

  @override
  void dispose() {
    _ignite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.current, longest = widget.longest;
    final t = _ignite.value;
    final k =
        _ignite.isAnimating ? (t < .35 ? t / .35 : 1 - (t - .35) / .65) : 0.0;
    return Row(
      children: [
        Transform.scale(
          scale: 1 + .18 * k,
          child: Container(
            key: _boxKey,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color.lerp(AppColors.orange.withValues(alpha: 0.12),
                  AppColors.orange.withValues(alpha: .35), k),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4 + .6 * k)),
              boxShadow: k > 0
                  ? [
                      BoxShadow(
                          color: AppColors.orange.withValues(alpha: .9 * k),
                          blurRadius: 26)
                    ]
                  : null,
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 22)),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Streak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  FlipSwap(
                    value: current,
                    child: Text(
                      '$current day${current == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (longest > 0)
                    Text(
                      ' · longest $longest',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keep-alive card (hero) — deadline countdown / safe / start-today
// ─────────────────────────────────────────────────────────────────────────────

class _KeepAliveCard extends StatelessWidget {
  const _KeepAliveCard({super.key, required this.streak});

  final StreakData streak;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last = streak.lastActivityDate?.toLocal();
    final loggedToday = last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;

    // Colour + icon + copy switch on the three states.
    final Color tint;
    final String icon;
    final String title;
    final String body;

    if (streak.current == 0) {
      tint = AppColors.blue;
      icon = '✨';
      title = 'Start your streak';
      body = 'Log one distance activity today to hit day 1.';
    } else if (loggedToday) {
      tint = AppColors.green;
      icon = '✓';
      title = 'Safe until midnight';
      body = 'Today already counts — next activity tomorrow.';
    } else {
      tint = AppColors.orange;
      icon = '⏳';
      final remaining = _timeLeftInDay(now);
      title = 'Streak at risk';
      body =
          'Log any distance activity before midnight to keep it alive. $remaining left.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tint,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLeftInDay(DateTime now) {
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final diff = endOfDay.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next milestone row
// ─────────────────────────────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.current});

  final int current;

  // Streak milestones + reward labels. Day 7 = ×1.5 XP, Day 30 = legendary
  // cosmetic per CLAUDE.md / design docs.
  static const _ladder = <int>[3, 7, 14, 30, 60, 100];

  String _rewardLabel(int milestone) {
    switch (milestone) {
      case 7:
        return '×1.5 XP bonus';
      case 30:
        return 'legendary cosmetic';
      case 100:
        return 'centurion title';
      default:
        return 'streak milestone';
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _ladder.firstWhere(
      (m) => m > current,
      orElse: () => -1,
    );
    if (next == -1) {
      // User past the last hard-coded milestone — show a generic brag line.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Legendary streak — $current days and counting.',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final remaining = next - current;
    final reward = _rewardLabel(next);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT MILESTONE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                FlipSwap(
                  value: remaining,
                  child: Text(
                    '$remaining day${remaining == 1 ? '' : 's'} to day $next',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward,
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(
                      end: next == 0 ? 0 : (current / next).clamp(0.0, 1.0)),
                  duration: AppMotion.duration(
                      context, const Duration(milliseconds: 600)),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 3,
                    backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                  ),
                ),
                FlipSwap(
                  value: current,
                  child: Text(
                    '$current/$next',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shields card — count + Use Shield CTA (closes LL-033)
// ─────────────────────────────────────────────────────────────────────────────

class _ShieldsCard extends StatelessWidget {
  const _ShieldsCard({
    required this.streak,
    required this.busy,
    required this.onUseShield,
  });

  final StreakData streak;
  final bool busy;
  final VoidCallback onUseShield;

  @override
  Widget build(BuildContext context) {
    final count = streak.shieldsAvailable;
    final canUse = streak.canUseShield;

    final String helperText;
    if (streak.shieldUsedToday) {
      helperText = 'Shield already protecting today.';
    } else if (count == 0) {
      helperText = 'Next shield earned every 7 active days.';
    } else if (streak.current == 0) {
      helperText = 'Start a streak before you can spend a shield.';
    } else {
      helperText =
          'Spend one to absorb a missed day without breaking your streak.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SHIELDS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$count available',
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            helperText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canUse && !busy ? onUseShield : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF2a3340),
                disabledForegroundColor: AppColors.textSecondary,
                elevation: canUse ? 4 : 0,
                shadowColor: AppColors.purple.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '🛡️ Use Shield',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer stats — total days active + last activity
// ─────────────────────────────────────────────────────────────────────────────

class _FooterStats extends StatelessWidget {
  const _FooterStats({
    required this.totalDaysActive,
    required this.lastActivityDate,
  });

  final int totalDaysActive;
  final DateTime? lastActivityDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            label: 'TOTAL DAYS',
            value: '$totalDaysActive',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCell(
            label: 'LAST ACTIVITY',
            value: _formatLast(lastActivityDate),
          ),
        ),
      ],
    );
  }

  String _formatLast(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(local.year, local.month, local.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
