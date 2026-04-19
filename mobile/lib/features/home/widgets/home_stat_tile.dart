import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'home_palette.dart';

/// One tile inside the compact stat strip (Banked / Today's XP / Shields).
/// Matches `.home3-strip__tile` in home-v3.html.
class HomeStatTile extends StatelessWidget {
  final String icon;
  final String label; // uppercase token e.g. "BANKED"
  final String value;
  final Color valueColor;
  final bool primary;
  final bool dim;
  final VoidCallback? onTap;

  const HomeStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.primary = false,
    this.dim = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValueColor = dim ? AppColors.textMuted : valueColor;
    final Widget tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kHSurface1,
        border: Border.all(
          color: primary
              ? AppColors.blue.withValues(alpha: 0.4)
              : kHBorderColor,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: primary
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 13, height: 1)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: effectiveValueColor,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    final wrapped = Opacity(opacity: dim ? 0.55 : 1.0, child: tile);
    if (onTap == null) return Expanded(child: wrapped);
    return Expanded(
      child: GestureDetector(onTap: onTap, child: wrapped),
    );
  }
}
