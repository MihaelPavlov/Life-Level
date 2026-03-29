import 'package:flutter/material.dart';
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
            ? const Color(0xFF1a2d1a)
            : isExpired
                ? const Color(0xFF1a1a1a)
                : const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF3fb950).withValues(alpha: 0.4)
              : isExpired
                  ? const Color(0xFF8b949e).withValues(alpha: 0.2)
                  : const Color(0xFF30363d),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _categoryEmoji(quest.category),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quest.title,
                  style: TextStyle(
                    color: isExpired
                        ? const Color(0xFF8b949e)
                        : const Color(0xFFe6edf3),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF3fb950).withValues(alpha: 0.2)
                      : const Color(0xFF4f9eff).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${quest.rewardXp} XP',
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF3fb950)
                        : const Color(0xFF4f9eff),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF3fb950),
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            quest.description,
            style: const TextStyle(color: Color(0xFF8b949e), fontSize: 13),
          ),
          if (!isCompleted && !isExpired) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: quest.progress,
                backgroundColor: const Color(0xFF1e2632),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4f9eff),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${_formatValue(quest.currentValue, quest.targetUnit)} / ${_formatValue(quest.targetValue, quest.targetUnit)} ${quest.targetUnit}',
                  style: const TextStyle(
                    color: Color(0xFF8b949e),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimeRemaining(quest.timeRemaining),
                  style: const TextStyle(
                    color: Color(0xFF8b949e),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ] else if (isExpired && !isCompleted) ...[
            const SizedBox(height: 6),
            const Text(
              'Expired',
              style: TextStyle(color: Color(0xFFf85149), fontSize: 12),
            ),
          ] else if (isCompleted) ...[
            const SizedBox(height: 6),
            const Text(
              'Completed · Reward claimed',
              style: TextStyle(color: Color(0xFF3fb950), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'duration':
        return '⏱️';
      case 'calories':
        return '🔥';
      case 'distance':
        return '📍';
      case 'workouts':
        return '🏋️';
      case 'streak':
        return '🔥';
      case 'login':
        return '📅';
      default:
        return '🎯';
    }
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
