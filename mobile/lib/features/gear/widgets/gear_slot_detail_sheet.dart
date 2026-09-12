import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../../character/providers/character_provider.dart';
import '../../items/models/item_models.dart';
import '../../items/providers/items_provider.dart';

/// Bottom sheet shown when tapping an equipped hex slot: item details +
/// stat bonuses + an Unequip action.
Future<void> showGearSlotDetailSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String slotType,
  required ItemDto item,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _GearSlotDetailSheet(slotType: slotType, item: item, ref: ref),
  );
}

class _GearSlotDetailSheet extends StatefulWidget {
  final String slotType;
  final ItemDto item;
  final WidgetRef ref;

  const _GearSlotDetailSheet({
    required this.slotType,
    required this.item,
    required this.ref,
  });

  @override
  State<_GearSlotDetailSheet> createState() => _GearSlotDetailSheetState();
}

class _GearSlotDetailSheetState extends State<_GearSlotDetailSheet> {
  bool _loading = false;

  Future<void> _unequip() async {
    setState(() => _loading = true);
    try {
      await widget.ref.read(equipmentProvider.notifier).unequip(widget.slotType);
      await widget.ref.read(inventoryProvider.notifier).refresh();
      widget.ref.read(characterProfileProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rColor = rarityColor(item.rarity);
    final bonuses = _bonusChips(item);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: rColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: rColor.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: ItemIconImage(
                      itemId: item.id,
                      itemName: item.name,
                      emojiFallback: item.icon,
                      size: 38,
                      emojiSize: 26,
                    ),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.rarity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: rColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (bonuses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 4, children: bonuses),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
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
                  : OutlinedButton(
                      onPressed: _unequip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Unequip',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bonusChips(ItemDto item) {
    final defs = [
      ('XP', item.xpBonusPct, AppColors.orange, true),
      ('STR', item.strBonus, AppColors.red, false),
      ('END', item.endBonus, AppColors.green, false),
      ('AGI', item.agiBonus, AppColors.blue, false),
      ('FLX', item.flxBonus, AppColors.purple, false),
      ('STA', item.staBonus, const Color(0xFFe3c35a), false),
    ];
    final chips = <Widget>[];
    for (final (label, value, color, isPct) in defs) {
      if (value <= 0) continue;
      final text = isPct ? '+$value% $label' : '+$value $label';
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      ));
    }
    return chips;
  }
}
