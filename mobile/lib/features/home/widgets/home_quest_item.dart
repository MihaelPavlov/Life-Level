import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'home_palette.dart';
import 'home_progress_bar.dart';

// ── Quest row inside Today's Quests card ─────────────────────────────────────
enum HomeQuestState { done, active, pending }

class HomeQuestItem extends StatelessWidget {
  final String icon;
  final HomeQuestState iconState;
  final String name;
  final String sub;
  final String xp;
  final bool done;
  final double? progress;
  final Color? progressColor;
  final bool isLast;

  const HomeQuestItem({
    super.key,
    required this.icon,
    required this.iconState,
    required this.name,
    required this.sub,
    required this.xp,
    required this.done,
    this.progress,
    this.progressColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconBg, iconBorder;
    switch (iconState) {
      case HomeQuestState.done:
        iconBg = AppColors.green.withValues(alpha: 0.1);
        iconBorder = AppColors.green.withValues(alpha: 0.3);
      case HomeQuestState.active:
        iconBg = AppColors.blue.withValues(alpha: 0.08);
        iconBorder = AppColors.blue.withValues(alpha: 0.25);
      case HomeQuestState.pending:
        iconBg = AppColors.textSecondary.withValues(alpha: 0.06);
        iconBorder = AppColors.textSecondary.withValues(alpha: 0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: kHBorderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              border: Border.all(color: iconBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  HomeProgressBar(
                    progress: progress!,
                    colors: [progressColor ?? AppColors.blue],
                    height: 4,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (done)
                const Text(
                  '✓',
                  style: TextStyle(fontSize: 16, color: AppColors.green, height: 1),
                ),
              Text(
                xp,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
