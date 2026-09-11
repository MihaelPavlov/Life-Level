import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Maps a backend talent `iconKey` to a bundled asset. Every seeded talent uses a
/// key that already exists under `assets/icons/`; unknown keys fall back to the sparkle.
String talentIconAsset(String key) {
  if (key.isEmpty) return 'assets/icons/reward_xp_sparkle.png';
  if (key.startsWith('item_')) return 'assets/Items/$key.png';
  if (key.startsWith('activity_')) return 'assets/icons/$key.png';
  return 'assets/icons/$key.png';
}

/// Rarity → accent colour (Common green / Rare blue / Epic orange).
Color talentRarityColor(String rarity) {
  switch (rarity) {
    case 'Epic':
      return AppColors.orange;
    case 'Rare':
      return AppColors.blue;
    case 'Common':
    default:
      return AppColors.green;
  }
}
