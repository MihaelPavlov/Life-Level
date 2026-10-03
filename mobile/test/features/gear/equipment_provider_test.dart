import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_level/features/items/models/item_models.dart';
import 'package:life_level/features/items/providers/items_provider.dart';
import 'package:life_level/features/items/services/items_service.dart';

class _FailingItemsService extends ItemsService {
  bool failRefresh = false;
  static final outfit = CharacterEquipmentResponse.fromJson({
    'slots': [
      {
        'slotType': 'Chest',
        'item': {
          'id': 'shirt',
          'name': 'Compression Shirt',
          'description': '',
          'icon': '',
          'rarity': 'Common',
          'slotType': 'Chest',
        },
      },
    ],
    'totalBonuses': <String, dynamic>{},
  });

  @override
  Future<CharacterEquipmentResponse> getEquipment() async {
    if (failRefresh) throw StateError('Refresh unavailable');
    return outfit;
  }

  @override
  Future<CharacterEquipmentResponse> equipItem({
    required String characterItemId,
    required String slotType,
  }) async => throw StateError('Server rejected equip');

  @override
  Future<CharacterEquipmentResponse> unequip(String slotType) async =>
      throw StateError('Server rejected unequip');
}

void main() {
  test('failed equip and unequip keep the last visible outfit', () async {
    final service = _FailingItemsService();
    final container = ProviderContainer(overrides: [
      itemsServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);
    await container.read(equipmentProvider.future);

    final notifier = container.read(equipmentProvider.notifier);
    await expectLater(notifier.equip('owned-shirt', 'Chest'), throwsStateError);
    expect(container.read(equipmentProvider).valueOrNull?.slotFor('Chest')?.item?.name,
        'Compression Shirt');

    await expectLater(notifier.unequip('Chest'), throwsStateError);
    expect(container.read(equipmentProvider).valueOrNull?.slotFor('Chest')?.item?.name,
        'Compression Shirt');

    service.failRefresh = true;
    await notifier.refresh();
    expect(container.read(equipmentProvider).valueOrNull?.slotFor('Chest')?.item?.name,
        'Compression Shirt');
  });
}
