import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/quest_models.dart';

class QuestCard extends StatelessWidget {
  final UserQuestProgress quest;

  const QuestCard({super.key, required this.quest});

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;
    final isExpired = quest.isExpired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.surfaceSuccess
            : isExpired
                ? AppColors.surfaceDisabled
                : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.green.withValues(alpha: 0.4)
              : isExpired
                  ? AppColors.textSecondary.withValues(alpha: 0.2)
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestCardHeader(quest: quest, isCompleted: isCompleted, isExpired: isExpired),
          const SizedBox(height: 6),
          Text(
            quest.description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (!isCompleted && !isExpired) ...[
            const SizedBox(height: 10),
            _QuestProgressRow(quest: quest),
          ] else if (isExpired && !isCompleted) ...[
            const SizedBox(height: 6),
            const Text(
              'Expired',
              style: TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ] else if (isCompleted) ...[
            const SizedBox(height: 6),
            const Text(
              'Completed · Reward claimed',
              style: TextStyle(color: AppColors.green, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestCardHeader extends StatelessWidget {
  final UserQuestProgress quest;
  final bool isCompleted;
  final bool isExpired;

  const _QuestCardHeader({
    required this.quest,
    required this.isCompleted,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          questCategoryEmoji(quest.category),
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            quest.title,
            style: TextStyle(
              color: isExpired ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _XpBadge(xp: quest.rewardXp, isCompleted: isCompleted),
        if (isCompleted) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.check_circle,
            color: AppColors.green,
            size: 20,
          ),
        ],
      ],
    );
  }
}

class _XpBadge extends StatelessWidget {
  final int xp;
  final bool isCompleted;

  const _XpBadge({required this.xp, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppColors.green : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isCompleted ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '+$xp XP',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuestProgressRow extends StatelessWidget {
  final UserQuestProgress quest;

  const _QuestProgressRow({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: quest.progress,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              '${_formatValue(quest.currentValue, quest.targetUnit)} / '
              '${_formatValue(quest.targetValue, quest.targetUnit)} ${quest.targetUnit}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              _formatTimeRemaining(quest.timeRemaining),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatValue(double val, String unit) {
    if (unit == 'km') return val.toStringAsFixed(1);
    return val.toInt().toString();
  }

  String _formatTimeRemaining(Duration d) {
    if (d.isNegative) return 'Expired';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m left';
    if (d.inMinutes > 0) return '${d.inMinutes}m left';
    return 'Expiring soon';
  }
}
