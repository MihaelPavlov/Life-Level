import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_models.dart';
import '../services/items_service.dart';

final itemsServiceProvider = Provider<ItemsService>((_) => ItemsService());

final equipmentProvider =
    AsyncNotifierProvider<EquipmentNotifier, CharacterEquipmentResponse>(
  EquipmentNotifier.new,
);

class EquipmentNotifier extends AsyncNotifier<CharacterEquipmentResponse> {
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
    state = AsyncData(await ref.read(itemsServiceProvider).unequip(slotType));
  }

  Future<void> equip(String characterItemId, String slotType) async {
    state = AsyncData(await ref.read(itemsServiceProvider).equipItem(
        characterItemId: characterItemId, slotType: slotType));
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
}
