import 'package:flutter/material.dart';

// ── Small coloured badge (used in headers / chips) ──────────────────────────
class HomeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const HomeBadge(this.label, this.color, {super.key, this.fontSize = 9.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
