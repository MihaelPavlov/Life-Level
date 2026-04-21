import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../main.dart' show navigatorKey;
import '../../features/auth/login_screen.dart';

class ApiClient {
  static const _baseUrl = 'https://819b-165-225-201-141.ngrok-free.app/api';
  static final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Dio get instance {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'jwt_token');
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  static Future<void> saveToken(String token) =>
      _storage.write(key: 'jwt_token', value: token);

  static Future<void> clearToken() => _storage.delete(key: 'jwt_token');

  static Future<String?> getToken() => _storage.read(key: 'jwt_token');

  static String get _webBase {
    return _baseUrl.endsWith('/api')
        ? _baseUrl.substring(0, _baseUrl.length - 4)
        : _baseUrl;
  }

  static Future<String> get adminPanelUrl async {
    final token = await _storage.read(key: 'jwt_token');
    final base = '$_webBase/admin/index.html';
    return token != null ? '$base?token=${Uri.encodeComponent(token)}' : base;
  }

  static Future<String> get adminMapUrl async {
    final token = await _storage.read(key: 'jwt_token');
    final base = '$_webBase/admin/map.html';
    return token != null ? '$base?token=${Uri.encodeComponent(token)}' : base;
  }

  static Future<bool> isAdmin() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) payload += '=';
      final claims = jsonDecode(utf8.decode(base64Decode(payload))) as Map<String, dynamic>;
      // ASP.NET Core serialises ClaimTypes.Role as this URI key
      final role = claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']
          ?? claims['role'];
      return role == 'Admin';
    } catch (_) {
      return false;
    }
  }
}
