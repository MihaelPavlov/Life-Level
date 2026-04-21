import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// 8-dot horizontal progress indicator used in the intro and outro modals.
/// Defaults match the HTML mockup: 8 positions, first active on intro and
/// last active on outro, with done-state dots filled in green.
class TutorialProgressDots extends StatelessWidget {
  /// Total number of dots to render. Defaults to 8 (intro + 6 bubbles + outro).
  final int total;

  /// Zero-based index of the currently active dot.
  final int activeIndex;

  /// Highest zero-based index (exclusive) treated as "done" (green). Typically
  /// `activeIndex` for intro (nothing done yet) or `total - 1` for outro.
  final int doneUpTo;

  /// Active dot accent colour. Defaults to blue for intro; callers override
  /// with green for the outro ("quest complete").
  final Color activeColor;

  const TutorialProgressDots({
    super.key,
    this.total = 8,
    required this.activeIndex,
    this.doneUpTo = 0,
    this.activeColor = AppColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == activeIndex;
        final isDone = i < doneUpTo && !isActive;
        Color fill;
        Color border;
        List<BoxShadow>? glow;
        if (isActive) {
          fill = activeColor;
          border = activeColor;
          glow = [BoxShadow(color: activeColor, blurRadius: 8)];
        } else if (isDone) {
          fill = AppColors.green;
          border = AppColors.green;
          glow = null;
        } else {
          fill = AppColors.surfaceElevated;
          border = AppColors.border;
          glow = null;
        }
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 1),
              boxShadow: glow,
            ),
          ),
        );
      }),
    );
  }
}
