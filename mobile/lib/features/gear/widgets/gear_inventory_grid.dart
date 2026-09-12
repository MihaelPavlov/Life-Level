import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../../items/models/item_models.dart';

class _MockItem {
  final String name;
  final String rarity;
  final String emoji;
  const _MockItem(this.name, this.rarity, this.emoji);
}

// A handful of hardcoded example items (using the real seeded item catalog's
// names/rarities so `ItemIconImage` resolves the real icon art) purely to
// dress out the Gear page's inventory section visually, matching the
// reference design's flat colored-tile grid. Not wired to any backend data
// or equip flow — see the Gear plan for the real inventory/equip system
// this superseded.
const _kMockItems = [
  _MockItem('Apex GPS Pro', 'Legendary', '⌚'),
  _MockItem('Gravity Boots', 'Legendary', '🥾'),
  _MockItem('Champion Gloves', 'Legendary', '🥊'),
  _MockItem('Storm Jacket', 'Epic', '🧥'),
  _MockItem('Trail Runner X5', 'Epic', '👟'),
  _MockItem('Aura Stone', 'Epic', '💎'),
  _MockItem('Cryo Jersey', 'Rare', '🎽'),
  _MockItem('Grip Wraps', 'Rare', '🧤'),
  _MockItem('Speed Spikes', 'Rare', '⚡'),
  _MockItem('Iron Headband', 'Common', '🎽'),
];

const _kGridColumns = 4;
const _kGridSpacing = 10.0;

/// Decorative inventory grid at the bottom of the Gear page — a hardcoded
/// preview of example gear, styled after the reference design's colored-tile
/// grid.
class GearInventoryGrid extends StatelessWidget {
  const GearInventoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _kGridColumns,
              crossAxisSpacing: _kGridSpacing,
              mainAxisSpacing: _kGridSpacing,
              childAspectRatio: 0.82,
            ),
            itemCount: _kMockItems.length,
            itemBuilder: (_, i) => _InventoryTile(item: _kMockItems[i]),
          ),
        ),
      ],
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final _MockItem item;
  const _InventoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final rColor = rarityColor(item.rarity);

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item.name)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: rColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: rColor.withValues(alpha: 0.45), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ItemIconImage(
                itemId: '',
                itemName: item.name,
                emojiFallback: item.emoji,
                size: 30,
                emojiSize: 24,
              ),
              const SizedBox(height: 4),
              const Text(
                'Lv.1',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
