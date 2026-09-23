import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/season_models.dart';

class SeasonService {
  final _dio = ApiClient.instance;

  Future<SeasonTrack> getTrack() async {
    final res = await _dio.get('/season');
    return SeasonTrack.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SeasonClaimResult> claimTier(int tier, String track) async {
    try {
      final res = await _dio.post(
        '/season/claim',
        data: {'tier': tier, 'track': track},
      );
      return SeasonClaimResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _errorMessage(e);
      final code = e.response?.statusCode;
      if (code == 403) throw SeasonPassRequiredException(message);
      if (code == 409) throw SeasonTileUnavailableException(message);
      throw SeasonException(message);
    }
  }

  Future<List<SeasonClaimResult>> claimAvailable() async {
    try {
      final res = await _dio.post('/season/claim-available');
      return (res.data as List)
          .map((e) => SeasonClaimResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw SeasonTileUnavailableException(_errorMessage(e));
    }
  }

  Future<SeasonTrack> purchaseFounderPass() async {
    try {
      final res = await _dio.post('/season/pass/purchase');
      return SeasonTrack.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw SeasonException(_errorMessage(e));
    }
  }

  String _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is String && data.trim().isNotEmpty) return data;
    return 'Something went wrong. Please try again.';
  }
}

class SeasonException implements Exception {
  final String message;
  const SeasonException(this.message);
  @override
  String toString() => message;
}

/// 409 — tier not reached yet, or already claimed.
class SeasonTileUnavailableException extends SeasonException {
  const SeasonTileUnavailableException(super.message);
}

/// 403 — Founder reward without the pass.
class SeasonPassRequiredException extends SeasonException {
  const SeasonPassRequiredException(super.message);
}
