import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// What the backend needs to verify an Apple sign-in.
class AppleCredential {
  final String identityToken;

  /// The nonce we generated. Apple puts its SHA-256 in the token, and the
  /// server checks the two match.
  final String rawNonce;

  const AppleCredential(this.identityToken, this.rawNonce);
}

class AppleSignInCoordinator {
  AppleSignInCoordinator._();

  static final instance = AppleSignInCoordinator._();

  /// Native Sign in with Apple. Android and web would need Apple's web flow,
  /// which isn't set up, so the button only shows on Apple platforms.
  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// The last availability answer, so a screen opened later can lay out the
  /// Apple orb on its first frame instead of popping it in (which would also
  /// shove the Google orb sideways).
  bool? get cachedAvailable => _available;
  bool? _available;
  Future<bool>? _checking;

  Future<bool> isAvailable() {
    if (!isSupportedPlatform) return Future.value(false);
    return _checking ??= () async {
      try {
        return _available = await SignInWithApple.isAvailable();
      } catch (_) {
        return _available = false;
      }
    }();
  }

  /// Null when the person closes Apple's sheet.
  Future<AppleCredential?> authenticate() async {
    final rawNonce = _generateNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final token = credential.identityToken;
      if (token == null || token.isEmpty) {
        throw const AppleSignInFlowException(
            'Apple did not return an identity token.');
      }
      return AppleCredential(token, rawNonce);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw const AppleSignInFlowException('Apple sign-in failed.');
    }
  }

  static String _generateNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}

class AppleSignInFlowException implements Exception {
  final String message;
  const AppleSignInFlowException(this.message);

  @override
  String toString() => message;
}
