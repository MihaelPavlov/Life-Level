import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/dungeon_floor_cleared_notifier.dart';
import 'reward_moment/reward_moment.dart';

/// Fired whenever `DungeonFloorClearedNotifier` emits an event.
///
///  • A single floor → a banner that doesn't block play (floors are
///    frequent), with the floor progress strip.
///  • The whole run → a full-screen takeover with the bonus XP.
void showDungeonFloorClearedOverlay(
  BuildContext context,
  DungeonFloorClearedEvent event,
) {
  final cleared = event.clearedFloorOrdinal;
  final total = event.totalFloors;

  if (!event.runCompleted) {
    RewardMoment.show(
      context,
      size: RewardMomentSize.banner,
      accent: AppColors.green,
      hero: const RewardEmoji('⚡'),
      label: 'Floor cleared',
      title: 'Floor $cleared of $total cleared',
      subtitle: cleared < total
          ? '${event.dungeonName} · Floor ${cleared + 1} is now active'
          : event.dungeonName,
      details: RewardMomentProgress(
          done: cleared, total: total, color: AppColors.green),
      primaryLabel: 'Nice',
    );
    return;
  }

  RewardMoment.show(
    context,
    size: RewardMomentSize.takeover,
    accent: AppColors.orange,
    hero: const RewardEmoji('🏆'),
    label: 'Dungeon conquered',
    title: '${event.dungeonName} cleared',
    subtitle: 'You beat all $total trials.',
    details: RewardMomentProgress(
        done: total, total: total, color: AppColors.orange),
    rewards: [
      if (event.bonusXpAwarded > 0)
        RewardLine.xp(event.bonusXpAwarded, label: 'Bonus XP'),
    ],
  );
}
