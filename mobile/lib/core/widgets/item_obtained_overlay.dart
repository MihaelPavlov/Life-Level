import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import 'app_toast.dart';
import '../../features/character/providers/character_provider.dart';
import '../../features/items/models/item_models.dart';
import '../../features/items/services/items_service.dart';
import '../../features/items/providers/items_provider.dart';
import 'item_icon_image.dart';
import 'reward_moment/reward_moment.dart';

Color _rarityColor(String rarity) {
  switch (rarity.toLowerCase()) {
    case 'common':
      return AppColors.green;
    case 'uncommon':
      return AppColors.blue;
    case 'rare':
      return AppColors.purple;
    case 'epic':
      return AppColors.orange;
    case 'legendary':
      return AppColors.red;
    default:
      return AppColors.blue;
  }
}

String _prettyRarity(String r) =>
    r.isEmpty ? '' : r[0].toUpperCase() + r.substring(1).toLowerCase();

/// A new item landed in the inventory (drop or shop purchase). The whole
/// card takes the rarity colour; "Equip now" equips it straight away.
void showItemObtainedOverlay(BuildContext context, ItemDto item) {
  final container = ProviderScope.containerOf(context, listen: false);
  final toastContext = Navigator.of(context, rootNavigator: true).context;
  final canEquip = item.characterItemId != null && !item.isEquipped;
  final rarity = _prettyRarity(item.rarity);

  final chips = <(String, Color)>[
    if (item.xpBonusPct > 0) ('+${item.xpBonusPct}% XP', AppColors.orange),
    if (item.strBonus > 0) ('+${item.strBonus} STR', AppColors.red),
    if (item.endBonus > 0) ('+${item.endBonus} END', AppColors.green),
    if (item.agiBonus > 0) ('+${item.agiBonus} AGI', AppColors.blue),
    if (item.flxBonus > 0) ('+${item.flxBonus} FLX', AppColors.purple),
    if (item.staBonus > 0) ('+${item.staBonus} STA', AppColors.orange),
  ];

  Future<void> equip() async {
    try {
      await ItemsService().equipItem(
        characterItemId: item.characterItemId!,
        slotType: item.slotType,
      );
      container.invalidate(equipmentProvider);
      container.invalidate(inventoryProvider);
      container.read(characterProfileProvider.notifier).refresh();
      if (toastContext.mounted) {
        AppToast.success(toastContext, '${item.name} equipped');
      }
    } catch (_) {
      if (toastContext.mounted) {
        AppToast.error(
            toastContext, "Couldn't equip ${item.name}. Try it from Gear.");
      }
    }
  }

  RewardMoment.show(
    context,
    size: RewardMomentSize.card,
    accent: _rarityColor(item.rarity),
    hero: ItemIconImage(
      itemId: item.id,
      itemName: item.name,
      emojiFallback: item.icon,
      size: 52,
      emojiSize: 28,
    ),
    label: rarity.isEmpty ? 'New item' : 'New item · $rarity',
    title: item.name,
    subtitle: item.description.isEmpty ? null : item.description,
    details: chips.isEmpty ? null : RewardMomentChips(chips: chips),
    primaryLabel: canEquip ? 'Equip now' : 'Nice',
    onPrimary: canEquip ? equip : null,
    secondaryLabel: canEquip ? 'Later' : null,
  );
}
