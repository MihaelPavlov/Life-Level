import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'home_palette.dart';

/// Circular avatar with XP progress ring and LV pill pinned to the bottom.
/// Matches the `.home3-avatar` spec from home-v3.html.
class HomeAvatarRing extends StatelessWidget {
  final String emoji;
  final int level;
  final double xpProgress; // 0.0 – 1.0
  final double size;

  const HomeAvatarRing({
    super.key,
    required this.emoji,
    required this.level,
    required this.xpProgress,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 6, // reserve room for overflowing LV pill
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ring
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(progress: xpProgress.clamp(0.0, 1.0)),
            ),
          ),
          // Avatar inside the ring
          Positioned(
            left: 6,
            top: 6,
            right: 6,
            bottom: 6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2b3240), Color(0xFF1a1f2a)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
          // LV pill anchored to the bottom-centre, partially overflowing.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.blue, AppColors.purple],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kHBgBase, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  'LV $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 3; // stroke-width / 2

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFF1e2632)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc (blue→purple gradient like the mockup)
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.blue, AppColors.purple],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2, // start at top
        progress * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
