import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../items/models/item_models.dart';
import '../profile_stat_metadata.dart';

// ── GearBonusesCard ───────────────────────────────────────────────────────────
// Shows the summed bonuses from all equipped items at the bottom of the tab.
// Renders nothing when no bonuses are active.
class GearBonusesCard extends StatelessWidget {
  final GearBonusesDto bonuses;
  const GearBonusesCard({super.key, required this.bonuses});

  @override
  Widget build(BuildContext context) {
    if (!bonuses.hasAnyBonus) return const SizedBox.shrink();

    final rows = <_BonusRow>[];
    if (bonuses.xpBonusPct > 0) {
      rows.add(_BonusRow(
          'XP Multiplier', '+${bonuses.xpBonusPct}%', kPGold));
    }
    if (bonuses.strBonus > 0) {
      rows.add(_BonusRow(
          'Strength boost', '+${bonuses.strBonus}', AppColors.red));
    }
    if (bonuses.endBonus > 0) {
      rows.add(_BonusRow(
          'Endurance boost', '+${bonuses.endBonus}', kPBlue));
    }
    if (bonuses.agiBonus > 0) {
      rows.add(_BonusRow(
          'Agility boost', '+${bonuses.agiBonus}', AppColors.green));
    }
    if (bonuses.flxBonus > 0) {
      rows.add(_BonusRow(
          'Flexibility boost', '+${bonuses.flxBonus}', kPPurple));
    }
    if (bonuses.staBonus > 0) {
      rows.add(_BonusRow(
          'Stamina boost', '+${bonuses.staBonus}', kPBlue));
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPBorder2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL GEAR BONUSES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: kPTextSec,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(
                          fontSize: 12, color: kPTextPri),
                    ),
                  ),
                  Text(
                    row.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: row.color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BonusRow {
  final String label;
  final String value;
  final Color color;
  const _BonusRow(this.label, this.value, this.color);
}
