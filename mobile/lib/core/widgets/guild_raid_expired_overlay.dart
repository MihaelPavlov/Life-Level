import 'package:flutter/material.dart';
import '../../features/boss/widgets/boss_icon.dart';
import '../../features/guild/models/guild_models.dart';
import '../constants/app_colors.dart';
import 'reward_moment/reward_moment.dart';

/// The raid timer ran out before the guild finished the boss. Same card as
/// a win, in the grey loss tone: no glow, no rewards, just what happened.
Future<void> showGuildRaidExpiredOverlay(
  BuildContext context,
  GuildRaidExpiredInfo info,
) {
  final left = info.maxHp <= 0 ? 0.0 : info.remainingHp / info.maxHp;
  return RewardMoment.show(
    context,
    size: RewardMomentSize.card,
    tone: RewardMomentTone.loss,
    accent: AppColors.red,
    hero: BossIcon(icon: info.bossIcon, size: 72, emojiSize: 48),
    label: 'Guild raid ended',
    title: '${info.bossName} escaped',
    subtitle: 'The raid timer ran out before your guild could finish it.',
    details: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RewardMomentHpBar(fraction: left),
        const SizedBox(height: 10),
        RewardMomentStats(rows: [
          ('Guild damage', '${_fmt(info.totalDamage)} / ${_fmt(info.maxHp)}'),
          ('HP left', _fmt(info.remainingHp)),
        ]),
      ],
    ),
    primaryLabel: 'Close',
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
