import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../character/providers/character_provider.dart';
import '../../streak/providers/streak_provider.dart';
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

    return Container(
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
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final daysAgo = dayIndex - i;
                final isToday = i == dayIndex;
                final isFuture = i > dayIndex;
                final isShieldedToday = isToday && shieldUsedToday;

                HomeStreakDotState state;
                if (isShieldedToday) {
                  state = HomeStreakDotState.shield;
                } else if (isToday && currentStreak > 0) {
                  state = HomeStreakDotState.today;
                } else if (!isFuture && daysAgo <= currentStreak - 1 && !isToday) {
                  state = HomeStreakDotState.done;
                } else if (isToday) {
                  // Today with no streak activity yet — show as future/pending
                  state = HomeStreakDotState.future;
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
        const Text('\uD83D\uDD25', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$current',
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
