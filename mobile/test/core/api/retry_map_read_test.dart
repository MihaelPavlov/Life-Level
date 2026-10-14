import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/api/retry_map_read.dart';

DioException _failure(DioExceptionType type, {int? status}) => DioException(
      requestOptions: RequestOptions(path: '/world/full'),
      type: type,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/world/full'),
              statusCode: status,
            ),
    );

void main() {
  test('transient failures retry with 1, 2, and 4 second delays', () async {
    var calls = 0;
    final delays = <Duration>[];
    final result = await retryMapRead(() async {
      calls++;
      if (calls <= 3) throw _failure(DioExceptionType.connectionError);
      return 'fresh';
    }, wait: (delay) async => delays.add(delay));
    expect(result, 'fresh');
    expect(calls, 4);
    expect(delays, const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ]);
  });

  test('server errors stop after the final retry', () async {
    var calls = 0;
    await expectLater(
      retryMapRead(() async {
        calls++;
        throw _failure(DioExceptionType.badResponse, status: 503);
      }, wait: (_) async {}),
      throwsA(isA<DioException>()),
    );
    expect(calls, 4);
  });

  test('authentication and ordinary client errors do not retry', () async {
    for (final status in [400, 401, 403, 404]) {
      var calls = 0;
      await expectLater(
        retryMapRead(() async {
          calls++;
          throw _failure(DioExceptionType.badResponse, status: status);
        }, wait: (_) async {}),
        throwsA(isA<DioException>()),
      );
      expect(calls, 1);
    }
  });

  test('rate limits retry', () async {
    var calls = 0;
    final result = await retryMapRead(() async {
      calls++;
      if (calls == 1) throw _failure(DioExceptionType.badResponse, status: 429);
      return true;
    }, wait: (_) async {});
    expect(result, isTrue);
    expect(calls, 2);
  });
}
