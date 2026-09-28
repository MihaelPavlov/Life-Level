import 'package:flutter/material.dart';
import 'home_palette.dart';

// ── Progress bar ───────────────────────────────────────────────────────────────
class HomeProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  final double height;

  /// Boss hits: a glowing orange ember behind the fill that burns down from
  /// the pre-hit value to [progress]. Null when idle.
  final double? burnProgress;

  const HomeProgressBar({
    super.key,
    required this.progress,
    required this.colors,
    this.height = 6,
    this.burnProgress,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: kHSurface2),
            if (burnProgress != null)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: burnProgress!.clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF5A623), Color(0xFFFFDD8A)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0xFFF5A623), blurRadius: 12),
                    ],
                  ),
                ),
              ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors.length > 1
                        ? colors
                        : [colors.first, colors.first],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
