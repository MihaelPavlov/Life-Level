import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../character/providers/character_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../../streak/widgets/streak_detail_sheet.dart';
import '../widgets/home_palette.dart';
import '../widgets/home_streak_dot.dart';

/// Slim 7-day streak strip that sits above the hero card.
/// Matches `.home3-streak` in home-v3.html.
class HomeStreakStrip extends ConsumerWidget {
  const HomeStreakStrip({super.key});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull;
    final currentStreak = profile?.currentStreak ?? streak?.current ?? 0;
    final shieldUsedToday = streak?.shieldUsedToday ?? false;

    final today = DateTime.now();
    final dayIndex = today.weekday - 1; // 0 = Mon, 6 = Sun
    final todayDate = DateUtils.dateOnly(today);
    final startOfWeek = today.subtract(Duration(days: dayIndex));

    // Use lastActivityDate + currentStreak to determine which calendar days
    // were active — avoids broken week-position math.
    final lastActivity = streak?.lastActivityDate?.toLocal();
    final lastActivityDate =
        lastActivity != null ? DateUtils.dateOnly(lastActivity) : null;

    bool isActiveDay(DateTime dayDate) {
      if (lastActivityDate == null || currentStreak == 0) return false;
      final first =
          lastActivityDate.subtract(Duration(days: currentStreak - 1));
      return !dayDate.isBefore(first) && !dayDate.isAfter(lastActivityDate);
    }

    // Days from the active streak window that fall before this week's Monday.
    final visibleActiveDays =
        currentStreak > 0 ? (dayIndex + 1).clamp(0, currentStreak) : 0;
    final hiddenDays =
        (currentStreak - visibleActiveDays).clamp(0, currentStreak);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showStreakDetailSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kHSurface1,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _Flame(current: currentStreak),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: kHBorderSoft),
            const SizedBox(width: 10),
            if (hiddenDays > 0) ...[
              _OverflowBadge(count: hiddenDays),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayDate = DateUtils.dateOnly(
                      startOfWeek.add(Duration(days: i)));
                  final isToday = dayDate == todayDate;
                  final isFuture = dayDate.isAfter(todayDate);
                  final active = isActiveDay(dayDate);
                  final isShieldedToday = isToday && shieldUsedToday;

                  HomeStreakDotState state;
                  if (isShieldedToday) {
                    state = HomeStreakDotState.shield;
                  } else if (isToday && active) {
                    state = HomeStreakDotState.done;
                  } else if (isToday) {
                    state = HomeStreakDotState.today;
                  } else if (!isFuture && active) {
                    state = HomeStreakDotState.done;
                  } else {
                    state = HomeStreakDotState.future;
                  }

                  return HomeStreakDot(
                    state: state,
                    label: _dayLabels[i],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Flame extends StatelessWidget {
  final int current;
  const _Flame({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          current == 0 ? 'Start today' : '$current',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  final int count;
  const _OverflowBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 7,
      fontWeight: FontWeight.w800,
      color: AppColors.orange,
      height: 1.2,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('···', style: style),
        Text('+$count', style: style),
      ],
    );
  }
}
