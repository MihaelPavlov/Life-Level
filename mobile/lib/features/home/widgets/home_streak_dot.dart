import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'home_palette.dart';

enum HomeStreakDotState { done, today, future, shield }

/// A single circular pip used inside the slim 7-day streak strip.
/// Matches `.home3-streak__dot` in home-v3.html.
class HomeStreakDot extends StatelessWidget {
  final HomeStreakDotState state;
  final String label;

  const HomeStreakDot({
    super.key,
    required this.state,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg, border, textColor;
    final String glyph;
    final Color labelColor;

    switch (state) {
      case HomeStreakDotState.done:
        bg = AppColors.green;
        border = AppColors.green;
        textColor = const Color(0xFF0b1a12);
        glyph = '\u2713'; // ✓
        labelColor = kHTextMuted;
      case HomeStreakDotState.today:
        bg = AppColors.orange.withValues(alpha: 0.15);
        border = AppColors.orange;
        textColor = AppColors.orange;
        glyph = '\u25CF'; // ●
        labelColor = AppColors.orange;
      case HomeStreakDotState.future:
        bg = Colors.transparent;
        border = AppColors.border;
        textColor = kHTextMuted;
        glyph = '';
        labelColor = kHTextMuted;
      case HomeStreakDotState.shield:
        bg = AppColors.purple.withValues(alpha: 0.12);
        border = AppColors.purple;
        textColor = AppColors.purple;
        glyph = '\uD83D\uDEE1'; // 🛡
        labelColor = kHTextMuted;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: glyph.isEmpty
              ? null
              : Text(
                  glyph,
                  style: TextStyle(
                    fontSize: 8,
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
