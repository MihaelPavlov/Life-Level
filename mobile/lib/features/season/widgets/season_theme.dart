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
  if (key.isEmpty || key == 'reward_xp_sparkle') {
    return 'assets/icons/reward_xp_crystals.png';
  }
  if (key.startsWith('item_')) return 'assets/Items/$key.png';
  if (key.startsWith('title_') || key.startsWith('rank_')) {
    return 'assets/Titles&Ranks/$key.png';
  }
  return 'assets/icons/$key.png';
}

/// Keeps the real reward artwork visible in every season state. Locked
/// rewards use a small corner badge instead of replacing/covering the asset.
class SeasonRewardAsset extends StatelessWidget {
  final String iconKey;
  final double size;
  final bool locked;
  final Widget? fallback;

  const SeasonRewardAsset({
    super.key,
    required this.iconKey,
    required this.size,
    this.locked = false,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Image.asset(
              seasonIconAsset(iconKey),
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  fallback ??
                  Icon(Icons.card_giftcard_rounded,
                      size: size * .8, color: AppColors.textMuted),
            ),
            if (locked)
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  width: size * .48,
                  height: size * .48,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundAlt,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: size * .28,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      );
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
