import 'package:dio/dio.dart';

/// A player-safe API failure. Technical response bodies never become UI text.
class ApiFailure implements Exception {
  final String code;
  final String message;
  final String? traceId;
  final int? statusCode;

  const ApiFailure({
    required this.code,
    required this.message,
    this.traceId,
    this.statusCode,
  });

  factory ApiFailure.from(Object error,
      {String fallback = 'Something went wrong. Please try again.'}) {
    if (error is ApiFailure) return error;
    if (error is! DioException) {
      final text = error.toString().replaceFirst(
          RegExp(r'^(Exception|Error):\s*', caseSensitive: false), '');
      final technical = RegExp(
          r'(DioException|SocketException|Npgsql|EntityFramework|DbContext|'
          r'SqlState|connection is already in a transaction|stack trace)',
          caseSensitive: false);
      return ApiFailure(
          code: 'unexpected_error',
          message: text.isEmpty || technical.hasMatch(text) ? fallback : text);
    }

    final status = error.response?.statusCode;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiFailure(
          code: 'timeout',
          message: 'The request took too long. Please try again.');
    }
    if (error.type == DioExceptionType.connectionError) {
      return const ApiFailure(
          code: 'offline',
          message: 'Could not connect. Check your connection and try again.');
    }
    if (status != null && status >= 500) {
      return ApiFailure(
          code: 'service_unavailable',
          message: 'Something went wrong. Please try again.',
          statusCode: status);
    }

    final data = error.response?.data;
    String? code;
    String? message;
    String? traceId;
    if (data is Map) {
      code = data['code'] as String?;
      message = data['message'] as String?;
      traceId = data['traceId'] as String?;
      final legacy = data['error'];
      if (message == null && legacy is String && !_looksLikeCode(legacy)) {
        message = legacy;
      }
      if (code == null && legacy is String && _looksLikeCode(legacy)) {
        code = legacy.toLowerCase();
      }
    }
    message ??= switch (status) {
      401 => 'Please sign in again.',
      403 => 'You cannot perform this action.',
      404 => 'The requested item was not found.',
      409 => 'This action cannot be completed right now.',
      429 => 'Too many attempts. Please try again shortly.',
      _ => fallback,
    };
    return ApiFailure(
        code: code ?? 'request_failed',
        message: message,
        traceId: traceId,
        statusCode: status);
  }

  static bool _looksLikeCode(String value) =>
      value.isNotEmpty &&
      value.length <= 80 &&
      RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(value);

  @override
  String toString() => message;
}

String playerErrorMessage(Object? error,
        {String fallback = 'Something went wrong. Please try again.'}) =>
    error == null
        ? fallback
        : ApiFailure.from(error, fallback: fallback).message;
