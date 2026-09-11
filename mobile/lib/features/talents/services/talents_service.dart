import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/talent_models.dart';

class TalentsService {
  final _dio = ApiClient.instance;

  Future<TalentScreen> getScreen() async {
    final res = await _dio.get('/talents');
    return TalentScreen.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TalentDrawResult> draw() async {
    try {
      final res = await _dio.post('/talents/draw');
      return TalentDrawResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _errorMessage(e);
      if (e.response?.statusCode == 409) {
        throw TalentInsufficientFundsException(message);
      }
      throw TalentException(message);
    }
  }

  Future<TalentUpgradeResult> upgrade(String key) async {
    try {
      final res = await _dio.post('/talents/$key/upgrade');
      return TalentUpgradeResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _errorMessage(e);
      if (e.response?.statusCode == 409) {
        throw TalentInsufficientFundsException(message);
      }
      throw TalentException(message);
    }
  }

  String _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is String && data.trim().isNotEmpty) return data;
    return 'Something went wrong. Please try again.';
  }
}

class TalentException implements Exception {
  final String message;
  const TalentException(this.message);
  @override
  String toString() => message;
}

/// 409 — not enough coins / tokens / shards, or already at max level.
class TalentInsufficientFundsException extends TalentException {
  const TalentInsufficientFundsException(super.message);
}
