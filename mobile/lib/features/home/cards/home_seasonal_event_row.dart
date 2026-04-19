import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Thin "seasonal event" row that extends the stat strip into a 2nd row.
/// Matches `.home3-season` in home-v3.html.
///
/// Scaffold only — passing [state] == null hides the row entirely.
/// Data wiring is owned by LL-012 (seasonal events system).
class HomeSeasonalEventRow extends StatelessWidget {
  final SeasonalEventUiState? state;
  final VoidCallback? onTap;

  const HomeSeasonalEventRow({super.key, this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s == null) return const SizedBox.shrink();

    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue.withValues(alpha: 0.12),
            AppColors.purple.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(s.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.18),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(s.progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 10),
      child: onTap == null
          ? row
          : GestureDetector(onTap: onTap, child: row),
    );
  }
}

/// Minimal UI-layer state model for the row. Real data provider lands
/// with LL-012.
class SeasonalEventUiState {
  final String icon;
  final String title;
  final String meta; // e.g. "Stage 3 of 5 · 4 days left · ×2 XP"
  final double progress; // 0.0–1.0

  const SeasonalEventUiState({
    required this.icon,
    required this.title,
    required this.meta,
    required this.progress,
  });
}
