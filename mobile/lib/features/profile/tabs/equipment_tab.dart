import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../character/providers/character_provider.dart';
import '../../items/models/item_models.dart';
import '../../items/providers/items_provider.dart';
import '../profile_stat_metadata.dart';
import '../widgets/equipment_paperdoll.dart';
import '../widgets/equipment_item_detail.dart';
import '../widgets/gear_bonuses_card.dart';

// ── EquipmentTab ──────────────────────────────────────────────────────────────
// Displays the paperdoll grid, selected-item detail card, and total gear
// bonuses. Tapping a slot selects it; tapping the same slot deselects it.
class EquipmentTab extends ConsumerStatefulWidget {
  const EquipmentTab({super.key});

  @override
  ConsumerState<EquipmentTab> createState() => _EquipmentTabState();
}

class _EquipmentTabState extends ConsumerState<EquipmentTab> {
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentProvider);

    return equipmentAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load equipment',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kPTextPri),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(equipmentProvider.notifier).refresh(),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.blue),
              ),
            ),
          ],
        ),
      ),
      data: (equipment) => _buildContent(equipment),
    );
  }

  Widget _buildContent(CharacterEquipmentResponse equipment) {
    final selectedItem =
        _selectedSlot != null ? equipment.slotFor(_selectedSlot!)?.item : null;

    return RefreshIndicator(
      color: AppColors.blue,
      backgroundColor: kPSurface,
      onRefresh: () => ref.read(equipmentProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EquipmentPaperdoll(
              equipment: equipment,
              selectedSlot: _selectedSlot,
              onSlotTap: (slotType) => setState(() {
                _selectedSlot =
                    _selectedSlot == slotType ? null : slotType;
              }),
            ),
            if (selectedItem != null && _selectedSlot != null)
              EquipmentItemDetail(
                item: selectedItem,
                slotType: _selectedSlot!,
                onUnequip: () async {
                  await ref
                      .read(equipmentProvider.notifier)
                      .unequip(_selectedSlot!);
                  ref.read(characterProfileProvider.notifier).refresh();
                  setState(() => _selectedSlot = null);
                },
              ),
            GearBonusesCard(bonuses: equipment.totalBonuses),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
