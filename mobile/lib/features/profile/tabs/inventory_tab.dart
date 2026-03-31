import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../items/models/item_models.dart';
import '../../items/providers/items_provider.dart';
import '../../items/services/items_service.dart';
import '../profile_stat_metadata.dart';
import '../widgets/equipment_slot_tile.dart';

// ── constants ─────────────────────────────────────────────────────────────────
const _kMaxSlots = 50;
const _kCategories = [
  'All',
  'Tracker',
  'Clothing',
  'Footwear',
  'Accessory',
  'Consumable',
];
const _kGridColumns = 4;
const _kGridSpacing = 8.0;
const _kGridPadding = 12.0;

// Stat bonus chip definitions: label builder, color.
const _kStatChips = [
  _StatChipDef('XP', AppColors.orange),
  _StatChipDef('STR', AppColors.red),
  _StatChipDef('END', AppColors.green),
  _StatChipDef('AGI', AppColors.blue),
  _StatChipDef('FLX', AppColors.purple),
  _StatChipDef('STA', Color(0xFFe3c35a)),
];

class _StatChipDef {
  final String key;
  final Color color;
  const _StatChipDef(this.key, this.color);
}

// ── InventoryTab ──────────────────────────────────────────────────────────────
class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  ItemDto? _selectedItem;
  String _activeCategory = 'All';

  List<ItemDto> _filtered(List<ItemDto> all) {
    if (_activeCategory == 'All') return all;
    return all.where((i) => i.category == _activeCategory).toList();
  }

  int _countFor(List<ItemDto> all, String cat) =>
      cat == 'All' ? all.length : all.where((i) => i.category == cat).length;

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return inventoryAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load inventory',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kPTextPri,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.blue),
              ),
            ),
          ],
        ),
      ),
      data: (items) => _buildContent(items),
    );
  }

  Widget _buildContent(List<ItemDto> items) {
    final filtered = _filtered(items);

    return RefreshIndicator(
      color: AppColors.blue,
      backgroundColor: kPSurface,
      onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _FilterRow(
              items: items,
              activeCategory: _activeCategory,
              countFor: (cat) => _countFor(items, cat),
              onSelect: (cat) => setState(() {
                _activeCategory = cat;
                _selectedItem = null;
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  _kGridPadding, 8, _kGridPadding, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${items.length} / $_kMaxSlots slots',
                  style: const TextStyle(
                    fontSize: 11,
                    color: kPTextSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No items in this category',
                    style: const TextStyle(fontSize: 13, color: kPTextSec),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(_kGridPadding),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _kGridColumns,
                    crossAxisSpacing: _kGridSpacing,
                    mainAxisSpacing: _kGridSpacing,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return _InventoryItemCard(
                      item: item,
                      isSelected: _selectedItem?.id == item.id,
                      onTap: () => setState(() {
                        _selectedItem =
                            _selectedItem?.id == item.id ? null : item;
                      }),
                    );
                  },
                ),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _selectedItem != null
                  ? _InventoryItemDetail(
                      key: ValueKey(_selectedItem!.id),
                      item: _selectedItem!,
                      onAction: () => setState(() => _selectedItem = null),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── _FilterRow ────────────────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final List<ItemDto> items;
  final String activeCategory;
  final int Function(String) countFor;
  final void Function(String) onSelect;

  const _FilterRow({
    required this.items,
    required this.activeCategory,
    required this.countFor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _kGridPadding),
        itemCount: _kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _kCategories[i];
          final active = cat == activeCategory;
          final count = countFor(cat);
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.blue.withOpacity(0.15)
                    : kPSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? AppColors.blue : kPBorder2,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Text(
                '$cat ($count)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.blue : kPTextSec,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── _InventoryItemCard ────────────────────────────────────────────────────────
class _InventoryItemCard extends StatelessWidget {
  final ItemDto item;
  final bool isSelected;
  final VoidCallback onTap;

  const _InventoryItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rColor = rarityColor(item.rarity);
    final borderColor =
        isSelected ? rColor : rColor.withOpacity(0.45);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: rColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected
              ? [BoxShadow(color: rColor.withOpacity(0.25), blurRadius: 10)]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: kPTextPri,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (item.isEquipped)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'E',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── _InventoryItemDetail ──────────────────────────────────────────────────────
class _InventoryItemDetail extends ConsumerStatefulWidget {
  final ItemDto item;
  final VoidCallback onAction;

  const _InventoryItemDetail({
    super.key,
    required this.item,
    required this.onAction,
  });

  @override
  ConsumerState<_InventoryItemDetail> createState() =>
      _InventoryItemDetailState();
}

class _InventoryItemDetailState extends ConsumerState<_InventoryItemDetail> {
  bool _loading = false;

  Future<void> _handleEquip() async {
    if (widget.item.characterItemId == null) return;
    setState(() => _loading = true);
    try {
      await ItemsService().equipItem(
        characterItemId: widget.item.characterItemId!,
        slotType: widget.item.slotType,
      );
      await Future.wait([
        ref.read(equipmentProvider.notifier).refresh(),
        ref.read(inventoryProvider.notifier).refresh(),
      ]);
      widget.onAction();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleUnequip() async {
    setState(() => _loading = true);
    try {
      await ref.read(equipmentProvider.notifier).unequip(widget.item.slotType);
      await ref.read(inventoryProvider.notifier).refresh();
      widget.onAction();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rColor = rarityColor(item.rarity);
    final bonuses = _buildBonusChips(item);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: rColor.withOpacity(0.08), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kPTextPri,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _CategoryBadge(
                          label: item.rarity.toUpperCase(),
                          color: rColor,
                        ),
                        const SizedBox(width: 6),
                        _CategoryBadge(
                          label: item.category,
                          color: kPTextSec,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: const TextStyle(fontSize: 14, color: kPTextSec),
          ),
          if (bonuses.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: bonuses,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.blue,
                      ),
                    ),
                  )
                : item.isEquipped
                    ? OutlinedButton(
                        onPressed: _handleUnequip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPTextSec,
                          side: const BorderSide(color: kPBorder2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Unequip',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: item.characterItemId != null
                            ? _handleEquip
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Equip',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBonusChips(ItemDto item) {
    final chips = <Widget>[];
    final values = [
      item.xpBonusPct,
      item.strBonus,
      item.endBonus,
      item.agiBonus,
      item.flxBonus,
      item.staBonus,
    ];
    for (var i = 0; i < _kStatChips.length; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final def = _kStatChips[i];
      final label = def.key == 'XP' ? '+$v% XP' : '+$v ${def.key}';
      chips.add(_StatBonusChip(label: label, color: def.color));
    }
    return chips;
  }
}

// ── _CategoryBadge ────────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── _StatBonusChip ────────────────────────────────────────────────────────────
class _StatBonusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatBonusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
