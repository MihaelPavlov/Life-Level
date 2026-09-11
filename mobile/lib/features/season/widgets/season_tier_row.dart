import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/season_models.dart';
import 'season_reward_slot.dart';

/// One row of the track: [Free slot] · [tier badge rail] · [Founder slot].
class SeasonTierRow extends StatelessWidget {
  final SeasonTier tier;
  final void Function(int tier, String track) onClaim;

  const SeasonTierRow({super.key, required this.tier, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final freeReached = tier.free.state == SeasonRewardState.received ||
        tier.free.state == SeasonRewardState.ready;
    final badgeReady = tier.free.state == SeasonRewardState.ready ||
        tier.founder.state == SeasonRewardState.ready;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      // IntrinsicHeight gives the Row a concrete height so the centered badge
      // rail lays out inside a scrolling ListView (which supplies unbounded
      // vertical constraints).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SeasonRewardSlot(
                reward: tier.free,
                isFounderLane: false,
                onClaim: () => onClaim(tier.tier, 'Free'),
              ),
            ),
            SizedBox(
              width: 44,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: freeReached
                          ? const Color(0xFF0f1c12)
                          : AppColors.surfaceElevated,
                      border: Border.all(
                        color: badgeReady
                            ? AppColors.green
                            : (freeReached
                                ? const Color(0xFF234a2a)
                                : AppColors.border),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: badgeReady
                          ? [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.4),
                                blurRadius: 12,
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      '${tier.tier}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: freeReached
                            ? AppColors.green
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (tier.isMilestone)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text('★',
                          style:
                              TextStyle(fontSize: 10, color: AppColors.purple)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SeasonRewardSlot(
                reward: tier.founder,
                isFounderLane: true,
                onClaim: () => onClaim(tier.tier, 'Founder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
