import '../../../core/api/api_client.dart';
import '../models/boss_list_item.dart';

class BossPageService {
  Future<List<BossListItem>> getAllBosses() async {
    final response = await ApiClient.instance.get('/boss');
    final list = response.data as List;
    return list
        .map((j) => BossListItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
