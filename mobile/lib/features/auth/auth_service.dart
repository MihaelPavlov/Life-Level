import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

class AuthService {
  final _dio = ApiClient.instance;

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(res.data);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(res.data);
  }
}

class AuthResult {
  final String token;
  final String username;
  final String characterId;

  AuthResult({
    required this.token,
    required this.username,
    required this.characterId,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'],
        username: json['username'],
        characterId: json['characterId'],
      );
}
