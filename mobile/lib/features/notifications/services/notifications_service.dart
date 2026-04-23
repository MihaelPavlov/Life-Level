import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/services/deep_link_notifier.dart';
import '../models/notification_models.dart';

/// Top-level background message handler.
///
/// firebase_messaging requires this function to exist as a top-level (or
/// static) function annotated with `@pragma('vm:entry-point')` so the
/// framework can wake a separate isolate to run it. Do NOT access Riverpod
/// or any app singleton state from here — this isolate has no access to
/// MainShell, providers, or navigation.
///
/// For v1 this is a no-op; actionable notifications route via
/// `onMessageOpenedApp` / `getInitialMessage`, both of which run in the
/// main isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty. See doc comment above.
}

/// Singleton-ish service that owns the FCM token lifecycle and the
/// foreground/background/cold-start message listeners.
///
/// [initialize] is idempotent — safe to call on every MainShell mount.
class NotificationsService {
  NotificationsService._();

  static final NotificationsService instance = NotificationsService._();

  bool _initialized = false;
  String? _cachedToken;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  /// Returns the last fetched FCM token (null if never fetched or if the
  /// platform does not support FCM).
  String? get cachedToken => _cachedToken;

  /// Fetches the current FCM token, caching it after the first call.
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    if (kIsWeb) return null;
    try {
      _cachedToken = await FirebaseMessaging.instance.getToken();
      return _cachedToken;
    } catch (e) {
      debugPrint('[NotificationsService] getToken failed: $e');
      return null;
    }
  }

  /// Requests permission, fetches the token, registers it with the backend,
  /// and wires up all listeners (token refresh, foreground, opened-app,
  /// cold-start).
  ///
  /// The [ref] argument is accepted for forward compatibility with features
  /// that may want to invalidate providers on notification arrival; this v1
  /// implementation does not use it.
  Future<bool> initialize(WidgetRef? ref) async {
    if (_initialized) return true;
    _initialized = true;

    // No FCM on web (Firebase not wired). Silent no-op so the rest of the
    // app boots normally in Chrome for admin/preview work.
    if (kIsWeb) return false;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!authorized) {
        debugPrint(
          '[NotificationsService] permission not granted: '
          '${settings.authorizationStatus}',
        );
        // Continue anyway — on Android pre-13 permission is auto-granted and
        // the status can be reported as `notDetermined` in some rare cases.
      }

      final token = await getToken();
      if (token != null) {
        await _registerTokenWithBackend(token);
      }

      _tokenRefreshSub =
          messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[NotificationsService] token refreshed');
        _cachedToken = newToken;
        await _registerTokenWithBackend(newToken);
      });

      _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
        // v1: just log. In-app banner is a separate ticket.
        debugPrint(
          '[NotificationsService] foreground message: '
          'id=${message.messageId} data=${message.data}',
        );
      });

      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint(
          '[NotificationsService] opened from background: data=${message.data}',
        );
        _dispatchDeepLink(message);
      });

      // Cold-start tap: the notification that launched the app (if any).
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[NotificationsService] cold-start message: data=${initialMessage.data}',
        );
        _dispatchDeepLink(initialMessage);
      }

      return authorized;
    } catch (e, st) {
      debugPrint('[NotificationsService] initialize failed: $e');
      debugPrint('$st');
      // Allow a future call to retry.
      _initialized = false;
      return false;
    }
  }

  /// POST /notifications/unregister-token. Call on logout so the server stops
  /// targeting this device.
  Future<void> unregister(String token) async {
    try {
      final body = UnregisterTokenRequest(token: token).toJson();
      await ApiClient.instance.post('/notifications/unregister-token', data: body);
    } catch (e) {
      debugPrint('[NotificationsService] unregister failed: $e');
    }
  }

  /// Tears down listeners. Typically not needed because the service lives for
  /// the entire app lifecycle, but provided for completeness.
  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedAppSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _openedAppSub = null;
    _initialized = false;
  }

  // ── internals ──────────────────────────────────────────────────────────

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final platform = _platformString();
      final body = RegisterTokenRequest(
        token: token,
        platform: platform,
      ).toJson();
      await ApiClient.instance.post('/notifications/register-token', data: body);
      debugPrint('[NotificationsService] token registered ($platform)');
    } catch (e) {
      debugPrint('[NotificationsService] register-token failed: $e');
    }
  }

  void _dispatchDeepLink(RemoteMessage message) {
    final raw = message.data['deeplink'];
    if (raw is! String || raw.isEmpty) return;
    try {
      final uri = Uri.parse(raw);
      DeepLinkNotifier.notify(uri);
    } catch (e) {
      debugPrint(
        '[NotificationsService] could not parse deeplink="$raw": $e',
      );
    }
  }

  String _platformString() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
