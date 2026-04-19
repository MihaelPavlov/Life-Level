import 'package:flutter/material.dart';
import 'home_palette.dart';

// ── Card container (surface + border + optional glow) ─────────────────────────
class HomeCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? glowColor;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const HomeCard({
    super.key,
    required this.child,
    this.borderColor,
    this.glowColor,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: kHSurface1,
        border: Border.all(color: borderColor ?? kHBorderColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor!, blurRadius: 24, spreadRadius: 0)]
            : null,
      ),
      child: child,
    );
  }
}
