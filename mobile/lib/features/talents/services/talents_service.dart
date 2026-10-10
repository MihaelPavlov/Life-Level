import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../models/talent_models.dart';

class TalentsService {
  final _dio = ApiClient.instance;

  Future<TalentScreen> getScreen() async {
    final res = await ApiClient.cachedGet('/talents', changedArea: 'talents');
    return TalentScreen.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TalentDrawResult> draw({String? operationId}) async {
    try {
      final res = await _dio.post('/talents/draw',
          options: operationId == null
              ? null
              : ApiClient.mutationOptions(operationId));
      return TalentDrawResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final failure = ApiFailure.from(e,
          fallback: 'Could not draw a talent card. Please try again.');
      if (e.response?.statusCode == 409) {
        throw TalentInsufficientFundsException(failure.message);
      }
      throw TalentException(failure.message);
    }
  }
}

class TalentException implements Exception {
  final String message;
  const TalentException(this.message);
  @override
  String toString() => message;
}

/// 409 — not enough coins / crystals, or already at max level.
class TalentInsufficientFundsException extends TalentException {
  const TalentInsufficientFundsException(super.message);
}
