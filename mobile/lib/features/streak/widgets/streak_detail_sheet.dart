import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/streak_models.dart';
import '../providers/streak_provider.dart';

/// Show the streak detail bottom sheet. Reused from the home streak strip,
/// the home header flame chip, and the profile 🔥 Streak tile.
Future<void> showStreakDetailSheet(BuildContext context) {
  return showModalBottomSheet(
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
                    child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2),
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
                  onUseShield: () => _handleUseShield(streak),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUseShield(StreakData streak) async {
    if (_shieldBusy) return;
    setState(() => _shieldBusy = true);
    try {
      final result =
          await ref.read(streakProvider.notifier).useShield();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.success ? AppColors.green : AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to use shield: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _shieldBusy = false);
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
    required this.onUseShield,
  });

  final StreakData streak;
  final bool shieldBusy;
  final VoidCallback onUseShield;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(current: streak.current, longest: streak.longest),
        const SizedBox(height: 16),
        _KeepAliveCard(streak: streak),
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

// ─────────────────────────────────────────────────────────────────────────────
// Header — 🔥 icon + title + subtitle
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.current, required this.longest});

  final int current;
  final int longest;

  @override
  Widget build(BuildContext context) {
    final subtitle = longest > 0
        ? '$current day${current == 1 ? '' : 's'} · longest $longest'
        : '$current day${current == 1 ? '' : 's'}';
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
          ),
          child: const Center(
            child: Text('🔥', style: TextStyle(fontSize: 22)),
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
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
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
  const _KeepAliveCard({required this.streak});

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
          border:
              Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
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
                Text(
                  '$remaining day${remaining == 1 ? '' : 's'} to day $next',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
                CircularProgressIndicator(
                  value: next == 0 ? 0 : (current / next).clamp(0.0, 1.0),
                  strokeWidth: 3,
                  backgroundColor:
                      AppColors.orange.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.orange),
                ),
                Text(
                  '$current/$next',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
    final canUse = count > 0 && !streak.shieldUsedToday && streak.current > 0;

    final String helperText;
    if (streak.shieldUsedToday) {
      helperText = 'Shield already protecting today.';
    } else if (count == 0) {
      helperText = 'Next shield earned every 7 active days.';
    } else if (streak.current == 0) {
      helperText = 'Start a streak before you can spend a shield.';
    } else {
      helperText = 'Spend one to absorb a missed day without breaking your streak.';
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
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
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
