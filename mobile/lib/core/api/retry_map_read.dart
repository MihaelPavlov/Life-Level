import 'package:dio/dio.dart';

/// Retry brief network/server failures before exposing an error in the map UI.
/// The wait can be replaced in tests so the retry policy stays fast to verify.
Future<T> retryMapRead<T>(
  Future<T> Function() read, {
  Future<void> Function(Duration delay)? wait,
}) async {
  final pause = wait ?? Future<void>.delayed;
  for (var attempt = 0;; attempt++) {
    try {
      return await read();
    } on DioException catch (error) {
      if (attempt >= 3 || !_isTransient(error)) rethrow;
      await pause(Duration(seconds: 1 << attempt));
    }
  }
}

bool _isTransient(DioException error) {
  final status = error.response?.statusCode;
  if (status != null) return status == 429 || status >= 500;
  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.unknown =>
      true,
    _ => false,
  };
}
