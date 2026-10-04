import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/character/models/level_up_receipt.dart';
import '../../features/items/models/item_models.dart' show rarityColor;
import '../../features/unlocks/models/unlock_catalog.dart';
import 'app_icon_image.dart';
import 'item_icon_image.dart';
import 'reward_moment/reward_moment.dart';

/// Full-screen level-up moment. [level] is the new level the player
/// reached; [unlocks] lists what it unlocked (stat points, zones, items).
/// When null or empty the moment shows a neutral line instead.
Future<void> showLevelUpScreen(BuildContext context, int level,
    {LevelUpUnlocks? unlocks, LevelUpReceipt? receipt}) {
  final list = <RewardUnlock>[
    // The features this level opens come first; their ceremonies follow
    // the level-up one at a time.
    for (final f in unlocksBetweenLevels(receipt?.previousLevel ?? level - 1, level))
      RewardUnlock(
        icon: AppIconImage(f.icon, size: 26),
        name: f.name,
        // Level-only features (and Achievements: a level-up means a workout
        // was logged) open right away; the rest also need their action.
        description: f.need.startsWith('Reach Level') ||
                f.key == UnlockKeys.achievements
            ? 'Opens now'
            : 'Opens when you ${f.need[0].toLowerCase()}${f.need.substring(1)}',
        badge: 'NEW FEATURE',
        color: f.color,
      ),
    if (receipt != null && receipt.totalStatPoints > 0)
      RewardUnlock(
        icon: const Icon(Icons.star_rounded, color: AppColors.orange),
        name:
            '+${receipt.totalStatPoints} Stat Point${receipt.totalStatPoints == 1 ? '' : 's'}',
        description: receipt.bonusStatPointsGranted > 0
            ? '${receipt.baseStatPointsGranted} from levels + ${receipt.bonusStatPointsGranted} bonus'
            : 'Spend on STR, END, AGI, FLX, or STA',
        badge: 'RECEIVED',
        color: AppColors.orange,
      ),
    if (receipt != null && receipt.powerGained > 0)
      RewardUnlock(
        icon: const Icon(Icons.bolt_rounded, color: AppColors.orange),
        name: '+${receipt.powerGained} Power',
        description: 'Permanent power gained from your new level',
        badge: 'RECEIVED',
        color: AppColors.orange,
      ),
    if (receipt != null && receipt.coinsGranted > 0)
      RewardUnlock(
        icon: const RewardEmoji('🪙'),
        name: '+${receipt.coinsGranted} Coins',
        description: 'Added to your wallet',
        badge: 'RECEIVED',
        color: AppColors.orange,
      ),
    if (receipt != null && receipt.talentCrystalsGranted > 0)
      RewardUnlock(
        icon: Image.asset(AppIcons.talentCrystalIcon, width: 28, height: 28),
        name: '+${receipt.talentCrystalsGranted} Talent Crystals',
        description: 'Added to your talent wallet',
        badge: 'RECEIVED',
        color: AppColors.purple,
      ),
    if (receipt != null &&
        receipt.newInventorySlots > receipt.previousInventorySlots)
      RewardUnlock(
        icon: const Icon(Icons.inventory_2_rounded, color: AppColors.blue),
        name:
            '${receipt.previousInventorySlots} → ${receipt.newInventorySlots} slots',
        description: 'Inventory capacity increased',
        badge: 'UPGRADED',
        color: AppColors.blue,
      ),
    if (unlocks != null && unlocks.statPointsGained > 0)
      RewardUnlock(
        icon: const Icon(Icons.star_rounded, color: AppColors.orange),
        name: unlocks.statPointsGained == 1
            ? '+1 Stat Point'
            : '+${unlocks.statPointsGained} Stat Points',
        description: 'Spend on STR, END, AGI, FLX, or STA',
        badge: 'POINTS',
        color: AppColors.orange,
      ),
    for (final zone in unlocks?.unlockedZones ?? const <UnlockedZoneInfo>[])
      RewardUnlock(
        icon: RewardEmoji(zone.icon.isNotEmpty ? zone.icon : '🗺️'),
        name: zone.name,
        description: zone.region.isEmpty
            ? 'New zone · Lvl ${zone.levelRequirement}'
            : '${zone.region} · Lvl ${zone.levelRequirement}',
        badge: 'ZONE',
        color: AppColors.blue,
      ),
    for (final item in unlocks?.grantedItems ?? const <GrantedItemInfo>[])
      RewardUnlock(
        icon: ItemIconImage(
          itemId: item.itemId,
          itemName: item.name,
          emojiFallback: item.icon.isNotEmpty ? item.icon : '🎁',
          size: 26,
          emojiSize: 20,
        ),
        name: item.name,
        description: item.slot.isEmpty
            ? _pretty(item.rarity)
            : '${_pretty(item.rarity)} · ${item.slot}',
        badge: item.rarity.isEmpty ? 'ITEM' : item.rarity.toUpperCase(),
        color: rarityColor(item.rarity),
      ),
    for (final title in receipt?.grantedTitles ?? const <LevelUpTitleInfo>[])
      RewardUnlock(
        icon: RewardEmoji(title.emoji.isEmpty ? '🏅' : title.emoji),
        name: title.name,
        description: 'Title added to your collection',
        badge: 'UNLOCKED',
        color: AppColors.purple,
      ),
    for (final item in receipt?.grantedItems ?? const <GrantedItemInfo>[])
      RewardUnlock(
        icon: ItemIconImage(
          itemId: item.itemId,
          itemName: item.name,
          emojiFallback: item.icon.isNotEmpty ? item.icon : '🎁',
          size: 26,
          emojiSize: 20,
        ),
        name: item.name,
        description: item.slot.isEmpty
            ? _pretty(item.rarity)
            : '${_pretty(item.rarity)} · ${item.slot}',
        badge: 'RECEIVED',
        color: rarityColor(item.rarity),
      ),
    for (final avatar
        in receipt?.availableAvatars ?? const <LevelUpAvatarInfo>[])
      RewardUnlock(
        icon: RewardEmoji(avatar.emoji.isEmpty ? '🧙' : avatar.emoji),
        name: avatar.name,
        description: 'Avatar now available · Level ${avatar.levelRequirement}',
        badge: 'AVAILABLE',
        color: AppColors.purple,
      ),
    for (final region
        in receipt?.availableRegions ?? const <LevelUpRegionInfo>[])
      RewardUnlock(
        icon: RewardEmoji(region.emoji.isEmpty ? '🗺️' : region.emoji),
        name: region.name,
        description: 'Level requirement met · Reach it through the World Map',
        badge: 'AVAILABLE',
        color: AppColors.blue,
      ),
    for (final blocked in receipt?.blockedItems ?? const <LevelUpBlockedItem>[])
      RewardUnlock(
        icon: RewardEmoji(blocked.icon.isEmpty ? '🎒' : blocked.icon),
        name: blocked.name,
        description: 'Inventory full — this item was not granted',
        badge: 'NOT GRANTED',
        color: AppColors.red,
      ),
  ];

  return RewardMoment.show(
    context,
    size: RewardMomentSize.takeover,
    accent: AppColors.blue,
    hero: _LevelBadge(level: level),
    label: 'Level up',
    title: 'Level $level',
    subtitle: receipt != null && receipt.levelsGained > 1
        ? '${receipt.levelsGained} levels gained · rewards grouped below'
        : list.isEmpty
            ? 'Your level increased. More rewards await ahead.'
            : 'Your hero grows stronger.',
    details: list.isEmpty ? null : RewardMomentUnlocks(unlocks: list),
    primaryLabel: 'Continue',
  );
}

String _pretty(String r) =>
    r.isEmpty ? 'Item' : r[0].toUpperCase() + r.substring(1).toLowerCase();

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'LEVEL',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.blue,
          ),
        ),
        Text(
          '$level',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}
