import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Per-season accent (the `theme` slug from the API). State colours
/// (orange = pending, green = ready) stay universal for usability.
class SeasonAccent {
  final Color accent;
  final Color accentSoft;

  const SeasonAccent(this.accent, this.accentSoft);

  static SeasonAccent of(String theme) {
    switch (theme) {
      case 'tide':
        return const SeasonAccent(Color(0xFF2bb8c4), Color(0x142bb8c4));
      case 'ember':
      default:
        return SeasonAccent(
            AppColors.orange, AppColors.orange.withValues(alpha: 0.10));
    }
  }
}

/// Maps a backend `iconKey` ("reward_treasure_chest", "item_aura_stone", …) to
/// a bundled asset path. Falls back to the generic reward sparkle.
String seasonIconAsset(String key) {
  if (key.isEmpty) return 'assets/icons/reward_xp_sparkle.png';
  if (key.startsWith('item_')) return 'assets/Items/$key.png';
  if (key.startsWith('title_') || key.startsWith('rank_')) {
    return 'assets/Titles&Ranks/$key.png';
  }
  return 'assets/icons/$key.png';
}

Color? seasonRarityColor(String? rarity) {
  switch (rarity) {
    case 'uncommon':
      return AppColors.blue;
    case 'rare':
      return AppColors.purple;
    case 'epic':
      return AppColors.orange;
    case 'legendary':
      return AppColors.red;
    default:
      return null;
  }
}
