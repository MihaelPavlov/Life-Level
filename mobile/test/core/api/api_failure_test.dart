import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/api/api_failure.dart';

void main() {
  DioException responseError(int status, dynamic data) => DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: status,
          data: data,
        ),
        type: DioExceptionType.badResponse,
      );

  test('reads canonical safe error envelope', () {
    final failure = ApiFailure.from(responseError(409, {
      'code': 'insufficient_currency',
      'message': 'Not enough coins.',
      'traceId': 'trace-1',
    }));

    expect(failure.code, 'insufficient_currency');
    expect(failure.message, 'Not enough coins.');
    expect(failure.traceId, 'trace-1');
  });

  test('supports legacy message envelope', () {
    final failure = ApiFailure.from(
        responseError(409, {'error': 'This reward was already claimed.'}));

    expect(failure.message, 'This reward was already claimed.');
  });

  test('never exposes a server 500 body', () {
    final failure = ApiFailure.from(responseError(500, {
      'error': 'A connection is already in a transaction',
      'traceId': 'trace-2',
    }));

    expect(failure.message, 'Something went wrong. Please try again.');
    expect(failure.message, isNot(contains('transaction')));
  });
}
