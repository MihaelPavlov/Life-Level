import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Tiny orange flame chip used in the home header.
/// Matches `.home3-streak-chip` in home-v3.html.
class HomeStreakChip extends StatelessWidget {
  final int streakDays;
  final VoidCallback? onTap;

  const HomeStreakChip({
    super.key,
    required this.streakDays,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = streakDays == 1
        ? '\uD83D\uDD25 1-day streak'
        : '\uD83D\uDD25 $streakDays-day streak';

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.orange,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}
