import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/quest_provider.dart';

class DailyBonusBanner extends ConsumerWidget {
  const DailyBonusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyQuestsProvider);
    final completed = dailyAsync.valueOrNull
            ?.where((q) => q.isCompleted)
            .length ??
        0;
    final total = dailyAsync.valueOrNull?.length ?? 5;
    final allDone = total > 0 && completed >= total;

    if (allDone) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'All Daily Quests Complete!',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '+300 XP Earned',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed / $total Daily Quests Complete',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SegmentedBar(filled: completed, total: total),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Bonus',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                '+300 XP',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SegmentedBar extends StatelessWidget {
  final int filled;
  final int total;

  const SegmentedBar({super.key, required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    final count = total > 0 ? total : 5;
    return Row(
      children: List.generate(count, (i) {
        final isDone = i < filled;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < count - 1 ? 3 : 0),
            decoration: BoxDecoration(
              color: isDone ? AppColors.blue : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
