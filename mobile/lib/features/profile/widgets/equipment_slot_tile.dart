import 'package:flutter/material.dart';
import '../../items/models/item_models.dart';
import '../profile_stat_metadata.dart';

// Returns the border/accent color for a given rarity string.
Color rarityColor(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'legendary':
      return const Color(0xFFf5a623);
    case 'epic':
      return const Color(0xFFa371f7);
    case 'rare':
      return const Color(0xFF4f9eff);
    case 'uncommon':
      return const Color(0xFF8b949e);
    default:
      return const Color(0xFF3fb950); // common
  }
}

// ── EquipmentSlotTile ─────────────────────────────────────────────────────────
// A 60×60 equipment slot. Shows item icon + rarity bar when equipped,
// or a "+" placeholder when empty. Blue border + glow when selected.
class EquipmentSlotTile extends StatelessWidget {
  final String slotType;
  final ItemDto? item;
  final bool isSelected;
  final VoidCallback onTap;

  const EquipmentSlotTile({
    super.key,
    required this.slotType,
    this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final equipped = item != null;
    final borderColor = isSelected
        ? kPBlue
        : equipped
            ? rarityColor(item!.rarity).withOpacity(0.6)
            : kPBorder2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: kPSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [BoxShadow(color: kPBlue.withOpacity(0.25), blurRadius: 8)]
              : null,
        ),
        child: equipped
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item!.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Container(
                    height: 3,
                    width: 36,
                    decoration: BoxDecoration(
                      color: rarityColor(item!.rarity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(Icons.add, size: 22, color: kPTextSec),
              ),
      ),
    );
  }
}
