import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/account_models.dart';
import 'apple_sign_in_coordinator.dart';

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

  Future<AuthResult> signInWithGoogle({
    required String idToken,
    String? currentPassword,
  }) async {
    try {
      final res = await _dio.post('/auth/google', data: {
        'idToken': idToken,
        if (currentPassword != null) 'currentPassword': currentPassword,
      });
      return AuthResult.fromJson(_asMap(res.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 409 &&
          data is Map &&
          data['code'] == 'account_link_required') {
        throw GoogleAccountLinkRequiredException(idToken);
      }
      throw AuthException(_serverMessage(
        e,
        fallback: 'Google sign-in failed. Please try again.',
      ));
    }
  }

  Future<AuthResult> signInWithApple({
    required AppleCredential credential,
    String? currentPassword,
  }) async {
    try {
      final res = await _dio.post('/auth/apple', data: {
        'identityToken': credential.identityToken,
        'nonce': credential.rawNonce,
        if (currentPassword != null) 'currentPassword': currentPassword,
      });
      return AuthResult.fromJson(_asMap(res.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 409 &&
          data is Map &&
          data['code'] == 'account_link_required') {
        throw const AppleAccountLinkRequiredException();
      }
      throw AuthException(_serverMessage(
        e,
        fallback: 'Apple sign-in failed. Please try again.',
      ));
    }
  }

  /// Null when the name can be used, else the reason it can't.
  Future<String?> usernameProblem(String username) async {
    final res = await _dio.get('/auth/username/available',
        queryParameters: {'username': username});
    final data = _asMap(res.data);
    return data['available'] == true
        ? null
        : (data['reason'] as String? ?? 'That name can’t be used.');
  }

  /// Sets (or keeps) the player's name and stores the refreshed token.
  Future<String> chooseUsername(String username) async {
    try {
      final res =
          await _dio.put('/auth/username', data: {'username': username});
      final data = _asMap(res.data);
      await ApiClient.saveToken(data['token'] as String);
      return data['username'] as String;
    } on DioException catch (e) {
      throw AuthException(_serverMessage(
        e,
        fallback: 'Couldn’t save that name. Please try again.',
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

  Future<void> setPasswordWithGoogle({
    required String googleIdToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post('/auth/password', data: {
        'googleIdToken': googleIdToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      });
    } on DioException catch (e) {
      throw AuthException(_serverMessage(
        e,
        fallback: 'Password setup failed.',
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

class GoogleAccountLinkRequiredException implements Exception {
  final String idToken;
  const GoogleAccountLinkRequiredException(this.idToken);
}

/// The Apple email matches an existing account; its password connects them.
class AppleAccountLinkRequiredException implements Exception {
  const AppleAccountLinkRequiredException();
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

  /// A Google or Apple sign-up still on its generated name.
  final bool needsUsername;

  AuthResult({
    required this.token,
    required this.username,
    required this.characterId,
    required this.ringItems,
    required this.isSetupComplete,
    this.needsUsername = false,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        username: json['username'] as String,
        characterId: json['characterId']?.toString(),
        ringItems: ((json['ringItems'] as List<dynamic>?) ?? const [])
            .map((e) => (e as String).toLowerCase())
            .toList(),
        isSetupComplete: json['isSetupComplete'] as bool? ?? false,
        needsUsername: json['needsUsername'] as bool? ?? false,
      );
}
