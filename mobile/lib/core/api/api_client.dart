import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const _baseUrl = 'http://localhost:5128/api';
  static const _storage = FlutterSecureStorage();

  static Dio get instance {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

    return dio;
  }

  static Future<void> saveToken(String token) =>
      _storage.write(key: 'jwt_token', value: token);

  static Future<void> clearToken() => _storage.delete(key: 'jwt_token');

  static Future<String?> getToken() => _storage.read(key: 'jwt_token');
}
