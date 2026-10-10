import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../models/region_chest_models.dart';

class RegionChestService {
  final _dio = ApiClient.instance;

  Future<RegionChestsOverview> getOverview() async {
    try {
      final response = await ApiClient.cachedGet(
        '/world/region-chests',
        changedArea: 'chests',
      );
      return RegionChestsOverview.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiFailure.from(error, fallback: 'Could not load region chests.');
    }
  }

  Future<RegionChestClaimResult> claim(String regionId) async {
    try {
      final response = await _dio.post('/world/region-chests/$regionId/claim');
      return RegionChestClaimResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiFailure.from(error, fallback: 'Could not claim the chest.');
    }
  }
}
