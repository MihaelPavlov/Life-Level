import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import 'app_icon_image.dart';
import '../../features/rewards/widgets/task_reward_popup.dart';

/// Opens a map zone chest with the same burst reveal as task rewards.
void showChestOpenedOverlay(
  BuildContext context, {
  required String zoneName,
  required int xp,
}) {
  unawaited(showRewardRevealPopup(
    context,
    items: [
      RewardRevealItem(
        asset: AppIcons.rewardXpCrystals,
        icon: const AppIconImage(
          AppIcons.rewardXpCrystals,
          size: 50,
          visualScale: 2.5,
        ),
        label: '+$xp XP',
        color: AppColors.blue,
      ),
    ],
    subtitle: zoneName,
    // The basic Wayfarer chest, same art as a Reward Road's first stage.
    heroAsset: AppIcons.shopChestCommon,
  ));
}
