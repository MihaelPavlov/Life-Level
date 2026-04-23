import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Small pill badge shown on region banners — "Active", "Completed ✓", or
/// "🔒 Lv N". Matches `.wv3-region__stat-badge` variants from the mockup.
class RegionStatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color borderColor;
  final Color textColor;

  const RegionStatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.borderColor,
    required this.textColor,
  });

  const RegionStatusChip.active({super.key})
      : label = 'Active',
        background = const Color(0x7F3fb950),
        borderColor = const Color(0x993fb950),
        textColor = Colors.white;

  const RegionStatusChip.completed({super.key})
      : label = 'Completed ✓',
        background = const Color(0x4C3fb950),
        borderColor = const Color(0x7F3fb950),
        textColor = Colors.white;

  RegionStatusChip.locked({super.key, required this.label})
      : background = AppColors.textSecondary.withOpacity(0.3),
        borderColor = Colors.white.withOpacity(0.18),
        textColor = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
