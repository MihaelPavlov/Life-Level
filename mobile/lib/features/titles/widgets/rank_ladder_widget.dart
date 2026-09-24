import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/title_rank_icons.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../profile/profile_stat_metadata.dart';
import '../models/title_models.dart';

const _kRankOrder = [
  'Novice',
  'Warrior',
  'Veteran',
  'Champion',
  'Legend',
];

class RankLadderWidget extends StatelessWidget {
  final RankProgressionDto progression;

  const RankLadderWidget({super.key, required this.progression});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _kRankOrder.indexOf(progression.currentRank);

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < _kRankOrder.length; i++) ...[
              _RankNode(
                rank: _kRankOrder[i],
                isUnlocked: i <= currentIndex,
                isCurrent: i == currentIndex,
              ),
              if (i < _kRankOrder.length - 1)
                _RankConnector(isUnlocked: i < currentIndex),
            ],
          ],
        ),
        const SizedBox(height: 14),
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
            'Maximum rank achieved',
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

class _RankNode extends StatelessWidget {
  final String rank;
  final bool isUnlocked;
  final bool isCurrent;

  const _RankNode({
    required this.rank,
    required this.isUnlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? profileRankColor(rank) : AppColors.border;
    final iconAsset = rankIconAsset(rank);

    return Expanded(
      child: Column(
        children: [
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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? color.withOpacity(0.15) : AppColors.surface,
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
              child: iconAsset != null
                  ? AppIconImage(
                      iconAsset,
                      size: 25,
                      visualScale: 1.3,
                      opacity: isUnlocked ? 1 : 0.45,
                    )
                  : Text(
                      rank.characters.first,
                      style: TextStyle(
                        fontSize: isUnlocked ? 16 : 14,
                        fontWeight: FontWeight.w800,
                        color: isUnlocked ? color : AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
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

class _RankConnector extends StatelessWidget {
  final bool isUnlocked;

  const _RankConnector({required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
