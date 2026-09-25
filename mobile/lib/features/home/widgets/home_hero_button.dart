import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'home_palette.dart';

enum HomeHeroButtonStyle {
  ghost,
  locked,
  solidBlue,
  solidGreen,
  solidRed,
  solidOrange,
  solidPurple,
}

/// Flat button used inside the Adventure Hero card.
/// Matches `.home3-btn` variants in home-v3.html.
class HomeHeroButton extends StatelessWidget {
  final String label;
  final HomeHeroButtonStyle style;
  final VoidCallback? onTap;

  /// Optional looping progress (0..1). While it passes .78–.92 a thin shine
  /// sweeps across the button — used by idle "go here" hints.
  final Animation<double>? shine;

  /// Optional looping progress (0..1). If the label ends in " →", the arrow
  /// nudges right late in each loop.
  final Animation<double>? nudge;

  const HomeHeroButton({
    super.key,
    required this.label,
    required this.style,
    required this.onTap,
    this.shine,
    this.nudge,
  });

  @override
  Widget build(BuildContext context) {
    final flex = style == HomeHeroButtonStyle.ghost ? 10 : 13;

    Color bgStart, bgEnd, borderColor, textColor;
    List<BoxShadow>? shadows;

    switch (style) {
      case HomeHeroButtonStyle.ghost:
        bgStart = kHSurface2;
        bgEnd = kHSurface2;
        borderColor = AppColors.border;
        textColor = AppColors.textSecondary;
        shadows = null;
      case HomeHeroButtonStyle.locked:
        bgStart = AppColors.red.withValues(alpha: 0.1);
        bgEnd = AppColors.red.withValues(alpha: 0.1);
        borderColor = AppColors.red.withValues(alpha: 0.55);
        textColor = AppColors.red;
        shadows = [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ];
      case HomeHeroButtonStyle.solidBlue:
        bgStart = AppColors.blue;
        bgEnd = const Color(0xFF3a88e6);
        borderColor = AppColors.blue.withValues(alpha: 0.5);
        textColor = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.25),
            blurRadius: 16,
          ),
        ];
      case HomeHeroButtonStyle.solidGreen:
        bgStart = AppColors.green;
        bgEnd = const Color(0xFF2ea043);
        borderColor = AppColors.green.withValues(alpha: 0.55);
        textColor = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ];
      case HomeHeroButtonStyle.solidRed:
        bgStart = AppColors.red;
        bgEnd = AppColors.redDark;
        borderColor = AppColors.red.withValues(alpha: 0.55);
        textColor = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ];
      case HomeHeroButtonStyle.solidOrange:
        bgStart = AppColors.orange;
        bgEnd = const Color(0xFFe08e14);
        borderColor = AppColors.orange.withValues(alpha: 0.55);
        textColor = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ];
      case HomeHeroButtonStyle.solidPurple:
        bgStart = AppColors.purple;
        bgEnd = const Color(0xFF8756d6);
        borderColor = AppColors.purple.withValues(alpha: 0.55);
        textColor = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.3),
            blurRadius: 16,
          ),
        ];
    }

    return Flexible(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgStart, bgEnd],
            ),
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
            boxShadow: shadows,
          ),
          alignment: Alignment.center,
          child: _withShine(_label(TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ))),
        ),
      ),
    );
  }

  Widget _label(TextStyle style) {
    final anim = nudge;
    if (anim == null || !label.endsWith(' →')) {
      return Text(label,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label.substring(0, label.length - 2),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
        AnimatedBuilder(
          animation: anim,
          builder: (_, child) {
            // Two small pushes (5 px, then 3 px) near the end of the loop.
            final t = anim.value;
            double dx = 0;
            if (t > .7 && t < .86) {
              dx = 5 * math.sin((t - .7) / .16 * math.pi);
            } else if (t >= .86 && t < .96) {
              dx = 3 * math.sin((t - .86) / .1 * math.pi);
            }
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Text(' →', style: style),
        ),
      ],
    );
  }

  Widget _withShine(Widget label) {
    final anim = shine;
    if (anim == null) return label;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        label,
        Positioned(
          left: -14,
          right: -14,
          top: -1,
          bottom: -1,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, __) {
                  final p = ((anim.value - .78) / .14).clamp(0.0, 1.0);
                  if (p <= 0 || p >= 1) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment(-1.4 + 2.8 * p, 0),
                    child: Transform(
                      transform: Matrix4.skewX(-.35),
                      child: Container(
                        width: 22,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Color(0x00FFFFFF),
                            Color(0x8CFFFFFF),
                            Color(0x00FFFFFF),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
