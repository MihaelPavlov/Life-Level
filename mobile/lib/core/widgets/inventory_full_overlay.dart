import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/nav_tab_notifier.dart';
import '../../features/activity/models/activity_models.dart';
import 'item_icon_image.dart';
import 'reward_moment/reward_moment.dart';

/// Returns a human-readable hint for the next inventory slot tier.
String _nextUnlockHint(int level) {
  if (level < 5) return 'Level 5 → 30 slots';
  if (level < 10) return 'Level 10 → 40 slots';
  if (level < 15) return 'Level 15 → 50 slots';
  if (level < 25) return 'Level 25 → 60 slots';
  if (level < 35) return 'Level 35 → 75 slots';
  if (level < 50) return 'Level 50 → 100 slots';
  return 'Max slots reached';
}

/// An earned item didn't fit. A problem to fix, not a win: a warning banner
/// with one action instead of a blocking dialog.
void showInventoryFullOverlay(
    BuildContext context, BlockedItemInfo item, int currentLevel) {
  final hint = _nextUnlockHint(currentLevel);
  RewardMoment.show(
    context,
    size: RewardMomentSize.banner,
    tone: RewardMomentTone.warning,
    accent: AppColors.orange,
    hero: ItemIconImage(
      itemId: item.itemId ?? '',
      itemName: item.itemName,
      emojiFallback: item.itemIcon,
      size: 48,
      emojiSize: 32,
    ),
    label: 'Inventory full',
    title: "${item.itemName} didn't fit",
    subtitle: hint == 'Max slots reached'
        ? 'Free a slot to make room.'
        : 'Free a slot, or reach $hint.',
    primaryLabel: 'Manage',
    onPrimary: () => NavTabNotifier.switchTo('profile'),
  );
}
