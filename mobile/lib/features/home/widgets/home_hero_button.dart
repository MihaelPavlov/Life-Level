import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'home_palette.dart';

enum HomeHeroButtonStyle {
  ghost,
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

  const HomeHeroButton({
    super.key,
    required this.label,
    required this.style,
    required this.onTap,
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
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
