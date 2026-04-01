import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/profile_stat_metadata.dart';
import '../models/title_models.dart';

// Ordered rank list used for index comparison.
const _kRankOrder = [
  'Novice',
  'Warrior',
  'Veteran',
  'Champion',
  'Legend',
];

const _kRankEmojis = {
  'Novice': '🌱',
  'Warrior': '⚔️',
  'Veteran': '🛡️',
  'Champion': '👑',
  'Legend': '🌟',
};

class RankLadderWidget extends StatelessWidget {
  final RankProgressionDto progression;

  const RankLadderWidget({super.key, required this.progression});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _kRankOrder.indexOf(progression.currentRank);

    return Column(
      children: [
        // Node row
        Row(
          children: [
            for (int i = 0; i < _kRankOrder.length; i++) ...[
              _RankNode(
                rank: _kRankOrder[i],
                emoji: _kRankEmojis[_kRankOrder[i]]!,
                isUnlocked: i <= currentIndex,
                isCurrent: i == currentIndex,
              ),
              if (i < _kRankOrder.length - 1)
                _RankConnector(
                  isUnlocked: i < currentIndex,
                ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // Hint text
        if (progression.nextRank != null)
          Text(
            'Defeat ${progression.bossesRemainingForNextRank} more '
            'boss${progression.bossesRemainingForNextRank == 1 ? '' : 'es'} '
            'to reach ${progression.nextRank}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          )
        else
          const Text(
            'Maximum rank achieved \u2728',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

// ── Single rank node ──────────────────────────────────────────────────────────
class _RankNode extends StatelessWidget {
  final String rank;
  final String emoji;
  final bool isUnlocked;
  final bool isCurrent;

  const _RankNode({
    required this.rank,
    required this.emoji,
    required this.isUnlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked
        ? profileRankColor(rank)
        : AppColors.border;

    return Expanded(
      child: Column(
        children: [
          // "YOU" label above current rank node
          SizedBox(
            height: 14,
            child: isCurrent
                ? const Text(
                    'YOU',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                : null,
          ),

          const SizedBox(height: 4),

          // Node circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? color.withOpacity(0.15)
                  : AppColors.surface,
              border: Border.all(
                color: isCurrent ? color : color.withOpacity(0.5),
                width: isCurrent ? 2.0 : 1.0,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: isUnlocked ? 16 : 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Rank name label
          Text(
            rank,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? color : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Connector line between nodes ──────────────────────────────────────────────
class _RankConnector extends StatelessWidget {
  final bool isUnlocked;

  const _RankConnector({required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Visually align the connector with the node circles (top area).
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        width: 12,
        height: 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppColors.orange.withOpacity(0.4)
                : AppColors.border,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
