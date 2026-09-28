import 'package:flutter/material.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/boss/widgets/boss_icon.dart';
import '../constants/app_colors.dart';
import 'reward_moment/reward_moment.dart';

/// The guild defeated its raid boss. A shared win, so the player's own
/// contribution sits right under the title, before the rewards.
Future<void> showGuildRaidVictoryOverlay(
  BuildContext context,
  GuildRaidVictoryInfo info,
) {
  final top = info.topContributorUsername;
  return RewardMoment.show(
    context,
    size: RewardMomentSize.takeover,
    accent: AppColors.purple,
    hero: BossIcon(icon: info.bossIcon, size: 72, emojiSize: 48),
    label: 'Guild raid cleared',
    title: '${info.bossName} falls',
    subtitle: 'Your guild brought it down.',
    details: RewardMomentStats(rows: [
      ('Your damage', _fmt(info.yourDamage)),
      ('Guild damage', _fmt(info.totalDamage)),
      if (top != null && top.isNotEmpty)
        ('Top contributor', '$top · ${_fmt(info.topContributorDamage)}'),
    ]),
    rewards: [
      RewardLine.xp(info.rewardXp, label: 'Raid XP'),
      if (info.mvpBonusXp > 0)
        RewardLine.xp(info.mvpBonusXp, label: 'MVP bonus'),
    ],
  );
}

String _fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
