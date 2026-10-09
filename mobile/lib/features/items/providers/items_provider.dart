import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_models.dart';
import '../services/items_service.dart';
import '../../../core/services/client_experience_service.dart';

final itemsServiceProvider = Provider<ItemsService>((_) => ItemsService());

final equipmentProvider =
    AsyncNotifierProvider<EquipmentNotifier, CharacterEquipmentResponse>(
  EquipmentNotifier.new,
);

class EquipmentNotifier extends AsyncNotifier<CharacterEquipmentResponse> {
  bool _mutating = false;
  @override
  Future<CharacterEquipmentResponse> build() =>
      ref.read(itemsServiceProvider).getEquipment();

  Future<void> refresh() async {
    try {
      state = AsyncData(await ref.read(itemsServiceProvider).getEquipment());
    } catch (_) {
      // Keep the last valid outfit while a passive refresh is unavailable.
    }
  }

  Future<void> unequip(String slotType) async {
    if (!ClientExperienceService.instance.enabled('achievementsEquipment')) {
      state = AsyncData(await ref.read(itemsServiceProvider).unequip(slotType));
      return;
    }
    if (_mutating) return;
    _mutating = true;
    final previous = state.requireValue;
    final inventoryBefore = ref.read(inventoryProvider).valueOrNull;
    state = AsyncData(previous.unequipLocally(slotType));
    _markInventory(slotType: slotType, equippedCharacterItemId: null);
    try {
      state = AsyncData(await ref.read(itemsServiceProvider).unequip(slotType));
    } catch (_) {
      state = AsyncData(previous);
      if (inventoryBefore != null) {
        ref.read(inventoryProvider.notifier).replaceLocally(inventoryBefore);
      }
      rethrow;
    } finally {
      _mutating = false;
    }
  }

  Future<void> equip(String characterItemId, String slotType) async {
    if (!ClientExperienceService.instance.enabled('achievementsEquipment')) {
      state = AsyncData(await ref
          .read(itemsServiceProvider)
          .equipItem(characterItemId: characterItemId, slotType: slotType));
      return;
    }
    if (_mutating) return;
    final inventoryBefore = ref.read(inventoryProvider).valueOrNull;
    final item = inventoryBefore?.items
        .where((item) => item.characterItemId == characterItemId)
        .firstOrNull;
    if (item == null) {
      state = AsyncData(await ref
          .read(itemsServiceProvider)
          .equipItem(characterItemId: characterItemId, slotType: slotType));
      return;
    }
    _mutating = true;
    final previous = state.requireValue;
    state = AsyncData(previous.equipLocally(item, slotType));
    _markInventory(
        slotType: slotType, equippedCharacterItemId: characterItemId);
    try {
      state = AsyncData(await ref
          .read(itemsServiceProvider)
          .equipItem(characterItemId: characterItemId, slotType: slotType));
    } catch (_) {
      state = AsyncData(previous);
      if (inventoryBefore != null) {
        ref.read(inventoryProvider.notifier).replaceLocally(inventoryBefore);
      }
      rethrow;
    } finally {
      _mutating = false;
    }
  }

  void _markInventory({
    required String slotType,
    required String? equippedCharacterItemId,
  }) {
    final inventory = ref.read(inventoryProvider).valueOrNull;
    if (inventory == null) return;
    ref.read(inventoryProvider.notifier).replaceLocally(InventoryResponse(
          maxSlots: inventory.maxSlots,
          items: [
            for (final item in inventory.items)
              item.slotType == slotType
                  ? item.copyWith(
                      isEquipped:
                          item.characterItemId == equippedCharacterItemId)
                  : item,
          ],
        ));
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, InventoryResponse>(
  InventoryNotifier.new,
);

class InventoryNotifier extends AsyncNotifier<InventoryResponse> {
  @override
  Future<InventoryResponse> build() =>
      ref.read(itemsServiceProvider).getInventory();

  Future<void> refresh() async {
    try {
      state = AsyncData(await ref.read(itemsServiceProvider).getInventory());
    } catch (_) {
      // Preserve the visible inventory until the next successful refresh.
    }
  }

  void replaceLocally(InventoryResponse value) => state = AsyncData(value);
}
