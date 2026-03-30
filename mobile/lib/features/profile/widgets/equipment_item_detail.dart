import 'package:flutter/material.dart';
import '../../items/models/item_models.dart';
import '../profile_stat_metadata.dart';
import 'equipment_slot_tile.dart';

// ── EquipmentItemDetail ───────────────────────────────────────────────────────
// Card displayed below the paperdoll when a slot with an item is selected.
// Shows icon, name, rarity badge, stat bonuses, and a stubbed unequip button.
class EquipmentItemDetail extends StatelessWidget {
  final ItemDto item;
  final String slotType;
  final VoidCallback onUnequip;

  const EquipmentItemDetail({
    super.key,
    required this.item,
    required this.slotType,
    required this.onUnequip,
  });

  @override
  Widget build(BuildContext context) {
    final rColor = rarityColor(item.rarity);
    final bonuses = _buildBonuses();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: rColor.withOpacity(0.08), blurRadius: 16),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item icon container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: rColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: rColor.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rarity badge row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kPTextPri,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: rColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: rColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        item.rarity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: rColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 11, color: kPTextSec),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Bonus chips
                if (bonuses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: bonuses.map((b) => _BonusChip(label: b)).toList(),
                  ),
                ],

                const SizedBox(height: 10),

                // Move to Inventory button (stubbed)
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Inventory coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPTextSec,
                      side: const BorderSide(color: kPBorder2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Move to Inventory',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildBonuses() {
    final result = <String>[];
    if (item.xpBonusPct > 0) result.add('+${item.xpBonusPct}% XP');
    if (item.strBonus > 0) result.add('+${item.strBonus} STR');
    if (item.endBonus > 0) result.add('+${item.endBonus} END');
    if (item.agiBonus > 0) result.add('+${item.agiBonus} AGI');
    if (item.flxBonus > 0) result.add('+${item.flxBonus} FLX');
    if (item.staBonus > 0) result.add('+${item.staBonus} STA');
    return result;
  }
}

// ── _BonusChip ────────────────────────────────────────────────────────────────
class _BonusChip extends StatelessWidget {
  final String label;
  const _BonusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kPBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kPBlue.withOpacity(0.30)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: kPBlue,
        ),
      ),
    );
  }
}
