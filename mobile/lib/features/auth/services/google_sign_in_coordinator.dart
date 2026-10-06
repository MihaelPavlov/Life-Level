import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInCoordinator {
  GoogleSignInCoordinator._();

  static final instance = GoogleSignInCoordinator._();
  static const _clientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  Future<void>? _initializing;

  bool get isConfigured => _clientId.isNotEmpty;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;

  Future<void> initialize() => _initializing ??= GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? _clientId : null,
        serverClientId: kIsWeb ? null : _clientId,
      );

  Future<String?> authenticate() async {
    if (!isConfigured) {
      throw const GoogleSignInFlowException(
          'Google sign-in is not configured for this build.');
    }
    await initialize();
    if (!GoogleSignIn.instance.supportsAuthenticate()) return null;
    final user = await GoogleSignIn.instance.authenticate();
    return _tokenFor(user);
  }

  String tokenForEvent(GoogleSignInAuthenticationEvent event) {
    if (event is! GoogleSignInAuthenticationEventSignIn) {
      throw const GoogleSignInFlowException('Google sign-in was cancelled.');
    }
    return _tokenFor(event.user);
  }

  String _tokenFor(GoogleSignInAccount user) {
    final token = user.authentication.idToken;
    if (token == null || token.isEmpty) {
      throw const GoogleSignInFlowException(
          'Google did not return an identity token.');
    }
    return token;
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    try {
      await initialize();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Local Life-Level logout must still succeed if the provider is unavailable.
    }
  }
}

class GoogleSignInFlowException implements Exception {
  final String message;
  const GoogleSignInFlowException(this.message);

  @override
  String toString() => message;
}
