import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import 'talent_theme.dart';

/// Small bottom-sheet explaining rarities, draw odds, and how Crystals differ
/// from Coins. Opened from the info button in the Talents header.
void showTalentInfoSheet(BuildContext context) {
  showAppBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _TalentInfoSheet(),
  );
}

class _TalentInfoSheet extends StatelessWidget {
  const _TalentInfoSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  'About Talents',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _rarityRow('Common', talentRarityColor('Common')),
            _rarityRow('Rare', talentRarityColor('Rare')),
            _rarityRow('Epic', talentRarityColor('Epic')),
            const SizedBox(height: 14),
            const Text(
              "Card draws favor talents you don't already own. If a draw "
              'lands on a talent you already have, that duplicate levels '
              'the card up. Maxed duplicate cards refund Coins and Crystals.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.5, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Card Draw prices increase after each successful draw. Your '
              'current Coin and Crystal cost is always shown on the draw button.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.5, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Crystals are needed for talent card draws. Each draw can '
              'unlock a new card or randomly upgrade one you already own. '
              'You earn Crystals by beating bosses, completing map regions, '
              "and claiming rewards like chests and daily login — not from routine activity logging "
              "(that's what Coins are for).",
              style: TextStyle(
                  fontSize: 12.5, height: 1.5, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rarityRow(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
