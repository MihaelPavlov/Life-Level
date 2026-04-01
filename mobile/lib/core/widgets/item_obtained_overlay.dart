import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../../features/character/providers/character_provider.dart';
import '../../features/items/models/item_models.dart';
import '../../features/items/services/items_service.dart';
import '../../features/items/providers/items_provider.dart';

// ── constants ──────────────────────────────────────────────────────────────────
const _kCardWidth    = 360.0;
const _kIconSize     = 80.0;
const _kBorderRadius = 20.0;
const _kCardBg       = Color(0xFF1e2632);
const _kBorder       = Color(0xFF30363d);

Color _rarityColor(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'common':    return AppColors.green;
    case 'uncommon':  return AppColors.blue;
    case 'rare':      return AppColors.purple;
    case 'epic':      return AppColors.orange;
    case 'legendary': return AppColors.red;
    default:          return AppColors.blue;
  }
}

/// Shows the "Item Obtained" popup card dialog with a slide-up + fade animation.
void showItemObtainedOverlay(BuildContext context, ItemDto item) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss item popup',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, __) => _ItemObtainedDialog(item: item),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _ItemObtainedDialog
// ─────────────────────────────────────────────────────────────────────────────
class _ItemObtainedDialog extends ConsumerWidget {
  final ItemDto item;
  const _ItemObtainedDialog({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rarityColor = _rarityColor(item.rarity);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: _kCardWidth,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(_kBorderRadius),
            border: Border.all(color: _kBorder, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── eyebrow ──────────────────────────────────────────────────
              Text(
                '✦ NEW ITEM ✦',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 20),

              // ── icon circle ──────────────────────────────────────────────
              Container(
                width: _kIconSize,
                height: _kIconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rarityColor.withValues(alpha: 0.12),
                  border: Border.all(color: rarityColor.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.30),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(item.icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(height: 16),

              // ── name + rarity badge ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.12),
                      border: Border.all(color: rarityColor.withValues(alpha: 0.30)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.rarity,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: rarityColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── description ──────────────────────────────────────────────
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),

              // ── stat chips ───────────────────────────────────────────────
              _StatChipsRow(item: item),
              const SizedBox(height: 20),

              // ── equip button (only if characterItemId is set) ────────────
              if (item.characterItemId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => _onEquipTap(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.blue, AppColors.purple],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.30),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Equip Now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── later button ─────────────────────────────────────────────
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Later',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onEquipTap(BuildContext context, WidgetRef ref) async {
    final svc = ItemsService();
    try {
      await svc.equipItem(
        characterItemId: item.characterItemId!,
        slotType: item.slotType,
      );
      ref.invalidate(equipmentProvider);
      ref.invalidate(inventoryProvider);
      ref.read(characterProfileProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not equip item: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatChipsRow — renders only chips for non-zero bonuses
// ─────────────────────────────────────────────────────────────────────────────
class _StatChipsRow extends StatelessWidget {
  final ItemDto item;
  const _StatChipsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final chips = <_StatChipData>[];
    if (item.xpBonusPct > 0) chips.add(_StatChipData('+${item.xpBonusPct}% XP', AppColors.orange));
    if (item.strBonus > 0)   chips.add(_StatChipData('+${item.strBonus} STR',    AppColors.red));
    if (item.endBonus > 0)   chips.add(_StatChipData('+${item.endBonus} END',    AppColors.green));
    if (item.agiBonus > 0)   chips.add(_StatChipData('+${item.agiBonus} AGI',    AppColors.blue));
    if (item.flxBonus > 0)   chips.add(_StatChipData('+${item.flxBonus} FLX',    AppColors.purple));
    if (item.staBonus > 0)   chips.add(_StatChipData('+${item.staBonus} STA',    AppColors.orange));

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: chips.map((c) => _StatChip(data: c)).toList(),
    );
  }
}

class _StatChipData {
  final String label;
  final Color color;
  const _StatChipData(this.label, this.color);
}

class _StatChip extends StatelessWidget {
  final _StatChipData data;
  const _StatChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.12),
        border: Border.all(color: data.color.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: data.color,
        ),
      ),
    );
  }
}
