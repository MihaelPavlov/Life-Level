import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../models/shop_models.dart';

class ShopService {
  final _dio = ApiClient.instance;
  Future<ShopData> getShop() async {
    try {
      return ShopData.fromJson(
          (await ApiClient.cachedGet('/shop', changedArea: 'shop')).data
              as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiFailure.from(error, fallback: 'Could not load the shop.');
    }
  }

  Future<ShopData> refresh() async {
    try {
      return ShopData.fromJson(
          (await _dio.post('/shop/refresh')).data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiFailure.from(error, fallback: 'Could not refresh the shop.');
    }
  }

  Future<ShopPurchaseResult> buyItem(String itemId, {String? operationId}) =>
      _purchase('/shop/items/$itemId/purchase', operationId: operationId);
  Future<ShopPurchaseResult> buyChest(String tier, {String? operationId}) =>
      _purchase('/shop/chests/$tier/purchase', operationId: operationId);

  Future<ShopPurchaseResult> _purchase(String path,
      {String? operationId}) async {
    final id = operationId ?? ApiClient.newOperationId();
    try {
      final response = await _dio.post(path,
          data: {'clientPurchaseId': id},
          options: ApiClient.mutationOptions(id));
      return ShopPurchaseResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final failure = ApiFailure.from(error,
          fallback: 'The purchase could not be completed. Please try again.');
      throw ShopException(failure.message);
    }
  }
}

class ShopException implements Exception {
  final String message;
  const ShopException(this.message);
  @override
  String toString() => message;
}
