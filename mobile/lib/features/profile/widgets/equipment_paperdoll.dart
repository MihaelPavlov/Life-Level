import 'package:flutter/material.dart';
import '../../items/models/item_models.dart';
import '../profile_stat_metadata.dart';
import 'equipment_slot_tile.dart';

// ── EquipmentPaperdoll ────────────────────────────────────────────────────────
// 3×3 grid layout mirroring the RPG paperdoll design:
//   Head         | Character center | Accessory1
//   Chest        | Mount badge      | Hands
//   Feet         | (spacer)         | Accessory2
class EquipmentPaperdoll extends StatelessWidget {
  final CharacterEquipmentResponse equipment;
  final String? selectedSlot;
  final void Function(String slotType) onSlotTap;

  const EquipmentPaperdoll({
    super.key,
    required this.equipment,
    required this.selectedSlot,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPBorder2),
      ),
      child: Column(
        children: [
          // Row 1: Head | Character | Accessory1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _slot('Head'),
              _characterCenter(),
              _slot('Accessory1'),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Chest | Mount | Hands
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _slot('Chest'),
              _mountBadge(),
              _slot('Hands'),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: Feet | (spacer) | Accessory2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _slot('Feet'),
              const SizedBox(width: 60),
              _slot('Accessory2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slot(String slotType) {
    final slotData = equipment.slotFor(slotType);
    return EquipmentSlotTile(
      slotType: slotType,
      item: slotData?.item,
      isSelected: selectedSlot == slotType,
      onTap: () => onSlotTap(slotType),
    );
  }

  Widget _characterCenter() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [kPBlue, kPPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kPBlue.withOpacity(0.30),
            blurRadius: 16,
          ),
        ],
      ),
      child: const Center(
        child: Text('🏃', style: TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _mountBadge() {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐾', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            'MOUNT',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: kPTextSec,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
