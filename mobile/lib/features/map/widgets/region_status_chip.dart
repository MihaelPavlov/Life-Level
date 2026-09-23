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
        background = const Color(0xE61E7138),
        borderColor = const Color(0xFF4DCC69),
        textColor = Colors.white;

  const RegionStatusChip.completed({super.key})
      : label = 'Completed ✓',
        background = const Color(0xE6185B30),
        borderColor = const Color(0xFF43B95D),
        textColor = Colors.white;

  RegionStatusChip.locked({super.key, required this.label})
      : background = AppColors.textSecondary.withValues(alpha: 0.3),
        borderColor = Colors.white.withValues(alpha: 0.18),
        textColor = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          shadows: const [
            Shadow(color: Color(0xCC000000), offset: Offset(0, 1)),
          ],
        ),
      ),
    );
  }
}
