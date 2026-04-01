// TODO: Add `crypto: ^3.0.3` to pubspec.yaml dependencies to enable PKCE SHA-256.
// Run `flutter pub add crypto` and then uncomment the crypto import below.
//
// ignore_for_file: unused_import
import 'dart:convert';
import 'dart:math';
// import 'package:crypto/crypto.dart'; // uncomment after adding crypto to pubspec.yaml
import '../../../core/api/api_client.dart';
import '../models/integration_models.dart';

class GarminService {
  static const _clientId = ''; // TODO: fill in after registering Garmin app
  static const _redirectUri = 'lifelevel://oauth/garmin';
  static const _scope = 'activity:read';

  /// Generate a cryptographically random code_verifier (PKCE).
  static String generateCodeVerifier() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Derive code_challenge from code_verifier (S256 method).
  ///
  /// Requires the `crypto` package. Until that is added to pubspec.yaml,
  /// this method returns the verifier as-is (plain method) so the OAuth
  /// flow can still be scaffolded without a compile error. Switch to S256
  /// once `crypto` is available.
  static String generateCodeChallenge(String verifier) {
    // TODO: replace with S256 once `crypto` is in pubspec.yaml:
    //   final bytes = utf8.encode(verifier);
    //   final digest = sha256.convert(bytes);
    //   return base64UrlEncode(digest.bytes).replaceAll('=', '');
    return verifier; // plain fallback — NOT secure for production
  }

  String authorizationUrl(String codeChallenge) {
    final params = {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'scope': _scope,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'https://connect.garmin.com/oauth2Confirm?$query';
  }

  Future<GarminStatusDto> getStatus() async {
    final response = await ApiClient.instance.get('/integrations/garmin/status');
    return GarminStatusDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GarminStatusDto> connect(String code, String codeVerifier) async {
    final response = await ApiClient.instance.post(
      '/integrations/garmin/connect',
      data: {
        'code': code,
        'codeVerifier': codeVerifier,
        'redirectUri': _redirectUri,
      },
    );
    return GarminStatusDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> disconnect() async {
    await ApiClient.instance.delete('/integrations/garmin/disconnect');
  }
}
