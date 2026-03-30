import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_models.dart';
import '../services/items_service.dart';

final _service = ItemsService();

final equipmentProvider =
    AsyncNotifierProvider<EquipmentNotifier, CharacterEquipmentResponse>(
  EquipmentNotifier.new,
);

class EquipmentNotifier extends AsyncNotifier<CharacterEquipmentResponse> {
  @override
  Future<CharacterEquipmentResponse> build() => _service.getEquipment();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_service.getEquipment);
  }

  Future<void> unequip(String slotType) async {
    state = await AsyncValue.guard(() => _service.unequip(slotType));
  }
}
