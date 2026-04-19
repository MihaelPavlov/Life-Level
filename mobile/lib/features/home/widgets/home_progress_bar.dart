import 'package:flutter/material.dart';
import 'home_palette.dart';

// ── Progress bar ───────────────────────────────────────────────────────────────
class HomeProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  final double height;

  const HomeProgressBar({
    super.key,
    required this.progress,
    required this.colors,
    this.height = 6,
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
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        colors.length > 1 ? colors : [colors.first, colors.first],
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
