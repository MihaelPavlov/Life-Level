import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../../character/providers/character_provider.dart';
import '../../items/models/item_models.dart';
import '../../items/providers/items_provider.dart';

/// Item details popup shown when tapping an item — from an equipped hex slot
/// or from the inventory grid: item details + stat bonuses + a Gear/Unequip
/// action that swaps depending on `item.isEquipped`. A centered card over a
/// dark scrim (not a bottom sheet), matching the reference mock's layout.
Future<void> showGearItemDetailSheet(
  BuildContext context, {
  required WidgetRef ref,
  required ItemDto item,
}) {
  return showAppDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Item details',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => _GearItemDetailDialog(item: item, ref: ref),
  );
}

class _GearItemDetailDialog extends StatefulWidget {
  final ItemDto item;
  final WidgetRef ref;

  const _GearItemDetailDialog({required this.item, required this.ref});

  @override
  State<_GearItemDetailDialog> createState() => _GearItemDetailDialogState();
}

class _GearItemDetailDialogState extends State<_GearItemDetailDialog> {
  // The popup closes immediately on tap rather than waiting for the network
  // call, so any failure is reported afterward via a SnackBar on the
  // underlying screen (captured before the pop, since `context` here won't
  // be mounted anymore once the dialog route is gone).
  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    try {
      await action();

      final equipmentState = widget.ref.read(equipmentProvider);
      if (equipmentState.hasError) {
        messenger.showSnackBar(
            SnackBar(content: Text(_friendlyError(equipmentState.error))));
        return;
      }

      await widget.ref.read(inventoryProvider.notifier).refresh();
      widget.ref.read(characterProfileProvider.notifier).refresh();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Something went wrong. Please try again.')));
    }
  }

  String _friendlyError(Object? error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _unequip() => _run(() => widget.ref
      .read(equipmentProvider.notifier)
      .unequip(widget.item.slotType));

  Future<void> _equip() {
    final characterItemId = widget.item.characterItemId;
    if (characterItemId == null) return Future.value();
    return _run(
      () => widget.ref
          .read(equipmentProvider.notifier)
          .equip(characterItemId, widget.item.slotType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rColor = rarityColor(item.rarity);
    final bonusRows = _bonusRows(item);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: rColor.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                        color: rColor.withValues(alpha: 0.28),
                        blurRadius: 32,
                        spreadRadius: -4),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(item: item, rarityColor: rColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _IconBox(item: item, rarityColor: rColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SlotPill(slotType: item.slotType),
                                    const SizedBox(height: 8),
                                    _DescriptionPanel(text: item.description),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (bonusRows.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const _SectionHeaderBar('BONUSES'),
                            const SizedBox(height: 10),
                            ...bonusRows,
                          ],
                          const SizedBox(height: 18),
                          _ActionButton(
                            isEquipped: item.isEquipped,
                            onEquip:
                                item.characterItemId == null ? null : _equip,
                            onUnequip: _unequip,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CloseButton(onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  List<Widget> _bonusRows(ItemDto item) {
    final defs = [
      ('✨', 'XP Bonus', item.xpBonusPct, AppColors.orange, true),
      ('💪', 'Strength', item.strBonus, AppColors.red, false),
      ('🏃', 'Endurance', item.endBonus, AppColors.blue, false),
      ('⚡', 'Agility', item.agiBonus, const Color(0xFF38d9c8), false),
      ('🧘', 'Flexibility', item.flxBonus, AppColors.purple, false),
      ('❤️', 'Stamina', item.staBonus, AppColors.orange, false),
    ];
    final rows = <Widget>[];
    for (final (emoji, label, value, color, isPct) in defs) {
      if (value <= 0) continue;
      rows.add(_BonusRow(
          emoji: emoji,
          label: label,
          value: value,
          color: color,
          isPct: isPct));
    }
    return rows;
  }
}

class _Header extends StatelessWidget {
  final ItemDto item;
  final Color rarityColor;
  const _Header({required this.item, required this.rarityColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [rarityColor.withValues(alpha: 0.35), AppColors.surface],
        ),
        border: Border(
            bottom: BorderSide(color: rarityColor.withValues(alpha: 0.35))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rarityColor.withValues(alpha: 0.7)),
            ),
            child: Text(
              item.rarity.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: rarityColor,
                  letterSpacing: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final ItemDto item;
  final Color rarityColor;
  const _IconBox({required this.item, required this.rarityColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: rarityColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rarityColor.withValues(alpha: 0.6), width: 2),
      ),
      child: Center(
        child: ItemIconImage(
            itemId: item.id,
            itemName: item.name,
            emojiFallback: item.icon,
            imageUrl: item.inventoryIconUrl,
            size: 54,
            emojiSize: 36),
      ),
    );
  }
}

class _SlotPill extends StatelessWidget {
  final String slotType;
  const _SlotPill({required this.slotType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${slotType.toUpperCase()} SLOT',
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
      ),
    );
  }
}

class _DescriptionPanel extends StatelessWidget {
  final String text;
  const _DescriptionPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 12.5, height: 1.3, color: AppColors.textSecondary),
    );
  }
}

class _SectionHeaderBar extends StatelessWidget {
  final String label;
  const _SectionHeaderBar(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _BonusRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final Color color;
  final bool isPct;

  const _BonusRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.isPct,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                children: [
                  TextSpan(text: '$label '),
                  TextSpan(
                    text: isPct ? '+$value%' : '+$value',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isEquipped;
  final VoidCallback? onEquip;
  final VoidCallback onUnequip;

  const _ActionButton({
    required this.isEquipped,
    required this.onEquip,
    required this.onUnequip,
  });

  @override
  Widget build(BuildContext context) {
    if (isEquipped) {
      return SizedBox(
        height: 46,
        child: ElevatedButton(
          onPressed: onUnequip,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('UNEQUIP',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onEquip,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('GEAR',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}
