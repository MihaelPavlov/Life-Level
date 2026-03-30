import '../../../core/api/api_client.dart';
import '../models/item_models.dart';

class ItemsService {
  final _dio = ApiClient.instance;

  Future<CharacterEquipmentResponse> getEquipment() async {
    final res = await _dio.get('/items/equipment');
    return CharacterEquipmentResponse.fromJson(
        res.data as Map<String, dynamic>);
  }

  Future<CharacterEquipmentResponse> equipItem({
    required String characterItemId,
    required String slotType,
  }) async {
    final res = await _dio.post('/items/equipment/equip', data: {
      'characterItemId': characterItemId,
      'slotType': slotType,
    });
    return CharacterEquipmentResponse.fromJson(
        res.data as Map<String, dynamic>);
  }

  Future<CharacterEquipmentResponse> unequip(String slotType) async {
    final res = await _dio.delete('/items/equipment/$slotType');
    return CharacterEquipmentResponse.fromJson(
        res.data as Map<String, dynamic>);
  }

  Future<List<ItemDto>> getInventory() async {
    final res = await _dio.get('/items/inventory');
    return (res.data as List<dynamic>)
        .map((e) => ItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
