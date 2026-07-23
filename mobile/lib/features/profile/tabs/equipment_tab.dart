import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../../character/providers/character_provider.dart';
import '../../items/models/item_models.dart';
import '../../items/providers/items_provider.dart';
import '../profile_stat_metadata.dart';
import '../widgets/equipment_paperdoll.dart';
import '../widgets/equipment_item_detail.dart';
import '../widgets/equipment_slot_tile.dart';
import '../widgets/gear_bonuses_card.dart';

// ── EquipmentTab ──────────────────────────────────────────────────────────────
// Displays the paperdoll grid, selected-item detail card, and total gear
// bonuses. Tapping a slot selects it; tapping the same slot deselects it.
class EquipmentTab extends ConsumerStatefulWidget {
  final VoidCallback? onOpenInventory;

  const EquipmentTab({super.key, this.onOpenInventory});

  @override
  ConsumerState<EquipmentTab> createState() => _EquipmentTabState();
}

class _EquipmentTabState extends ConsumerState<EquipmentTab> {
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(equipmentProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

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
      data: (equipment) => _buildContent(equipment, inventoryAsync.valueOrNull),
    );
  }

  Widget _buildContent(
    CharacterEquipmentResponse equipment,
    InventoryResponse? inventory,
  ) {
    final selectedItem =
        _selectedSlot != null ? equipment.slotFor(_selectedSlot!)?.item : null;
    final unequippedItems =
        inventory?.items.where((item) => !item.isEquipped).toList() ?? [];

    return RefreshIndicator(
      color: AppColors.blue,
      backgroundColor: kPSurface,
      onRefresh: () async {
        await Future.wait([
          ref.read(equipmentProvider.notifier).refresh(),
          ref.read(inventoryProvider.notifier).refresh(),
        ]);
      },
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
                  await ref.read(inventoryProvider.notifier).refresh();
                  ref.read(characterProfileProvider.notifier).refresh();
                  setState(() => _selectedSlot = null);
                },
              ),
            if (unequippedItems.isNotEmpty)
              _InventoryNudge(
                items: unequippedItems,
                onOpenInventory: widget.onOpenInventory,
              ),
            GearBonusesCard(bonuses: equipment.totalBonuses),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InventoryNudge extends StatelessWidget {
  final List<ItemDto> items;
  final VoidCallback? onOpenInventory;

  const _InventoryNudge({
    required this.items,
    required this.onOpenInventory,
  });

  @override
  Widget build(BuildContext context) {
    final previewItems = items.take(4).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPBorder2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 34,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < previewItems.length; i++)
                  Positioned(
                    left: i * 28,
                    child: _PreviewItem(item: previewItems[i]),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${items.length} item${items.length == 1 ? '' : 's'} in inventory',
              style: const TextStyle(
                color: kPTextPri,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onOpenInventory,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue,
              side: BorderSide(color: AppColors.blue.withOpacity(0.5)),
              minimumSize: const Size(70, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Inventory',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final ItemDto item;

  const _PreviewItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(item.rarity);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: kPBg,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.75), width: 1.4),
      ),
      child: Center(
        child: ItemIconImage(
          itemId: item.id,
          itemName: item.name,
          emojiFallback: item.icon,
          size: 23,
          emojiSize: 18,
        ),
      ),
    );
  }
}
