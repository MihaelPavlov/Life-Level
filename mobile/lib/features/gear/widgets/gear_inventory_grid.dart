import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../../items/models/item_models.dart';
import '../../items/providers/items_provider.dart';
import 'gear_slot_detail_sheet.dart';

const _kGridColumns = 4;
const _kGridSpacing = 10.0;

/// Inventory grid at the bottom of the Gear page. Backed by the real
/// `/items/inventory` data — tapping a tile opens the shared item detail
/// sheet, which equips or unequips depending on the item's current state.
class GearInventoryGrid extends ConsumerWidget {
  const GearInventoryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'INVENTORY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: inventoryAsync.when(
            data: (inventory) => inventory.items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No items yet',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _kGridColumns,
                      crossAxisSpacing: _kGridSpacing,
                      mainAxisSpacing: _kGridSpacing,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: inventory.items.length,
                    itemBuilder: (_, i) =>
                        _InventoryTile(item: inventory.items[i]),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.blue),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final ItemDto item;
  const _InventoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final rColor = rarityColor(item.rarity);
    final equipped = item.isEquipped;

    return GestureDetector(
      onTap: () => showGearItemDetailSheet(context, item: item),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: rColor.withValues(alpha: equipped ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    equipped ? AppColors.blue : rColor.withValues(alpha: 0.45),
                width: equipped ? 2.4 : 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ItemIconImage(
                    itemId: item.id,
                    itemName: item.name,
                    emojiFallback: item.icon,
                    imageUrl: item.inventoryIconUrl,
                    size: 30,
                    emojiSize: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.rarity,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (equipped)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
