import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/account_models.dart';

class AuthService {
  final _dio = ApiClient.instance;

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'role': isAdmin ? 2 : 0, // 2 = Admin, 0 = Player
      });
      return AuthResult.fromJson(_asMap(res.data));
    } on DioException catch (e) {
      throw AuthException(_serverMessage(
        e,
        fallback:
            'Registration failed. Email or username may already be taken.',
      ));
    }
  }

  Future<void> saveRingConfig(List<String> itemIds) async {
    // Convert lowercase ids to PascalCase for the C# enum
    final items = itemIds.map((id) {
      return id[0].toUpperCase() + id.substring(1);
    }).toList();
    await _dio.put('/user/ring', data: {'items': items});
  }

  Future<AuthResult> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'emailOrUsername': emailOrUsername,
        'password': password,
      });
      return AuthResult.fromJson(_asMap(res.data));
    } on DioException catch (e) {
      throw AuthException(_serverMessage(
        e,
        fallback: 'Invalid email or password.',
      ));
    }
  }

  Future<AccountInfo> getAccount() async {
    final res = await _dio.get('/auth/account');
    return AccountInfo.fromJson(_asMap(res.data));
  }

  Future<UpdateEmailResult> updateEmail({
    required String email,
    required String currentPassword,
  }) async {
    try {
      final res = await _dio.put('/auth/email', data: {
        'email': email,
        'currentPassword': currentPassword,
      });
      return UpdateEmailResult.fromJson(_asMap(res.data));
    } on DioException catch (e) {
      throw AuthException(_serverMessage(
        e,
        fallback: 'Email update failed.',
      ));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.put('/auth/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
    } on DioException catch (e) {
      throw AuthException(_serverMessage(
        e,
        fallback: 'Password update failed.',
      ));
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Unexpected auth response from server.');
  }

  String _serverMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return fallback;
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final String username;
  final String? characterId;
  final List<String> ringItems;
  final bool isSetupComplete;

  AuthResult({
    required this.token,
    required this.username,
    required this.characterId,
    required this.ringItems,
    required this.isSetupComplete,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        username: json['username'] as String,
        characterId: json['characterId']?.toString(),
        ringItems: ((json['ringItems'] as List<dynamic>?) ?? const [])
            .map((e) => (e as String).toLowerCase())
            .toList(),
        isSetupComplete: json['isSetupComplete'] as bool? ?? false,
      );
}
