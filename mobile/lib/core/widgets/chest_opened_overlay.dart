import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'reward_moment/reward_moment.dart';

/// Opening a chest zone on the region map: a card with the zone's emoji and
/// the XP it held, which flies into the XP ring on claim.
void showChestOpenedOverlay(
  BuildContext context, {
  required String zoneName,
  required int xp,
  String emoji = '🎁',
}) {
  RewardMoment.show(
    context,
    size: RewardMomentSize.card,
    accent: AppColors.orange,
    hero: RewardEmoji(emoji),
    label: 'Chest opened',
    title: zoneName,
    subtitle: 'The chest is empty now. Its rewards are yours.',
    rewards: [RewardLine.xp(xp)],
  );
}
