import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/shop_models.dart';

class ShopService {
  final _dio = ApiClient.instance;
  Future<ShopData> getShop() async => ShopData.fromJson(
      (await ApiClient.cachedGet('/shop', changedArea: 'shop')).data
          as Map<String, dynamic>);
  Future<ShopData> refresh() async => ShopData.fromJson(
      (await _dio.post('/shop/refresh')).data as Map<String, dynamic>);
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
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        throw ShopException(data['message'] as String);
      }
      throw const ShopException(
          'The purchase could not be completed. Please try again.');
    }
  }
}

class ShopException implements Exception {
  final String message;
  const ShopException(this.message);
  @override
  String toString() => message;
}
