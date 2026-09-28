import 'package:flutter/material.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/boss/widgets/boss_icon.dart';
import '../constants/app_colors.dart';
import 'reward_moment/reward_moment.dart';

/// Fired whenever `BossDefeatedNotifier` emits — an activity log finished a
/// boss off. Mini-bosses are frequent, so they get a card; full bosses take
/// several days of workouts and get the whole screen.
void showBossDefeatedOverlay(
  BuildContext context,
  BossDefeatedInfo info,
) {
  RewardMoment.show(
    context,
    size: info.isMini ? RewardMomentSize.card : RewardMomentSize.takeover,
    accent: AppColors.red,
    hero: BossIcon(
      icon: info.icon.isEmpty ? '👹' : info.icon,
      size: 72,
      emojiSize: 48,
    ),
    label: info.isMini ? 'Mini-boss slain' : 'Boss slain',
    title: info.isMini ? '${info.name} is down' : '${info.name} vanquished',
    subtitle: 'The path forward is yours.',
    rewards: [if (info.rewardXp > 0) RewardLine.xp(info.rewardXp)],
  );
}
