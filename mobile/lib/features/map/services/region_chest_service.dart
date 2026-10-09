import '../../../core/api/api_client.dart';
import '../models/region_chest_models.dart';

class RegionChestService {
  final _dio = ApiClient.instance;

  Future<RegionChestsOverview> getOverview() async {
    final response = await ApiClient.cachedGet(
      '/world/region-chests',
      changedArea: 'chests',
    );
    return RegionChestsOverview.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RegionChestClaimResult> claim(String regionId) async {
    final response = await _dio.post('/world/region-chests/$regionId/claim');
    return RegionChestClaimResult.fromJson(
        response.data as Map<String, dynamic>);
  }
}
