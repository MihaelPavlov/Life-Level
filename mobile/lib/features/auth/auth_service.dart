import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';

class AuthService {
  final _dio = ApiClient.instance;

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
      'role': isAdmin ? 2 : 0, // 2 = Admin, 0 = Player
    });
    return AuthResult.fromJson(res.data);
  }

  Future<void> saveRingConfig(List<String> itemIds) async {
    // Convert lowercase ids to PascalCase for the C# enum
    final items = itemIds.map((id) {
      return id[0].toUpperCase() + id.substring(1);
    }).toList();
    await _dio.put('/user/ring', data: {'items': items});
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
        token: json['token'],
        username: json['username'],
        characterId: json['characterId'],
        ringItems: (json['ringItems'] as List<dynamic>)
            .map((e) => (e as String).toLowerCase())
            .toList(),
        isSetupComplete: json['isSetupComplete'] as bool,
      );
}
