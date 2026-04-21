import 'package:flutter/material.dart';

/// Which way the tail points. Matches the four placements in
/// [BubblePlacement] with an explicit direction enum so the tail widget
/// stays a pure-drawing concern.
enum TailDirection {
  /// Tail on the bubble's top edge, pointing up.
  up,

  /// Tail on the bubble's bottom edge, pointing down.
  down,
}

/// Thin triangle pointer rendered below/above the bubble so the user's eye
/// follows target ↔ text. The triangle is stroked on two sides with the
/// accent color (matching the bubble border) and filled with the bubble's
/// background gradient end color so it reads as "part of" the bubble.
class TutorialBubbleTail extends StatelessWidget {
  final TailDirection direction;
  final Color accentColor;
  final Color fillColor;
  final double width;
  final double height;

  const TutorialBubbleTail({
    super.key,
    required this.direction,
    required this.accentColor,
    required this.fillColor,
    this.width = 16,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _TailPainter(
          direction: direction,
          accent: accentColor,
          fill: fillColor,
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final TailDirection direction;
  final Color accent;
  final Color fill;

  _TailPainter({
    required this.direction,
    required this.accent,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    if (direction == TailDirection.down) {
      // Tail on bubble's bottom edge, tip pointing down.
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w / 2, h);
      path.close();
    } else {
      // Tail on bubble's top edge, tip pointing up.
      path.moveTo(0, h);
      path.lineTo(w, h);
      path.lineTo(w / 2, 0);
      path.close();
    }

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fill;
    canvas.drawPath(path, fillPaint);

    // Stroke only the two slanted sides so the shared edge with the bubble
    // is invisible — otherwise there'd be a visible line at the join.
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = accent.withValues(alpha: 0.45);
    final sides = Path();
    if (direction == TailDirection.down) {
      sides.moveTo(0, 0);
      sides.lineTo(w / 2, h);
      sides.lineTo(w, 0);
    } else {
      sides.moveTo(0, h);
      sides.lineTo(w / 2, 0);
      sides.lineTo(w, h);
    }
    canvas.drawPath(sides, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) =>
      old.direction != direction ||
      old.accent != accent ||
      old.fill != fill;
}
