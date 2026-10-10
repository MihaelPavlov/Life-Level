import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show navigatorKey;
import '../motion/app_motion.dart';
import '../../features/auth/login_screen.dart';
import '../services/state_change_notifier.dart';

class ApiClient {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static final String _baseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : kIsWeb
          ? 'http://127.0.0.1:5128/api'
          : 'http://10.0.2.2:5128/api';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static String? _cachedToken;
  static bool _tokenLoaded = false;
  static final Dio _dio = _createDio();
  static bool persistentCacheEnabled = false;
  static const _cachePrefix = 'lifelevel.response_cache.v1';
  static Future<void>? _pendingFullCacheClear;
  static final Map<String, Future<void>> _pendingAreaInvalidations = {};

  static Dio _createDio() {
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
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (options.method != 'GET' && options.method != 'HEAD') {
          options.headers.putIfAbsent('Idempotency-Key', newOperationId);
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isAuthRequest = error.requestOptions.path.startsWith('/auth/');
        // Already logged out (a request that left without a token, or the
        // logout's own background calls): Login is on screen, don't push it
        // again.
        final loggedIn = await getToken() != null;
        if (error.response?.statusCode == 401 && !isAuthRequest && loggedIn) {
          await _storage.delete(key: 'jwt_token');
          navigatorKey.currentState?.pushAndRemoveUntil(
            AppRoute(
                builder: (_) => const LoginScreen(), style: AppRouteStyle.fade),
            (_) => false,
          );
        }
        handler.next(error);
      },
      onResponse: (response, handler) {
        final method = response.requestOptions.method;
        final isMutation = method != 'GET' && method != 'HEAD';
        final isTelemetry =
            response.requestOptions.path == '/client-experience/events';
        final changed = response.headers.value('x-lifelevel-changed-areas');
        if (isMutation && !isTelemetry) {
          if (changed == null || changed.trim().isEmpty) {
            _scheduleFullCacheClear();
          } else {
            _scheduleAreaInvalidation(changed.split(','));
          }
        }
        if (changed != null) StateChangeNotifier.notify(changed.split(','));
        handler.next(response);
      },
    ));

    return dio;
  }

  static Dio get instance => _dio;

  static String newOperationId() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static Options mutationOptions(String operationId) => Options(
        headers: {'Idempotency-Key': operationId},
      );

  static Future<Response<dynamic>> cachedGet(
    String path, {
    required String changedArea,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!persistentCacheEnabled) {
      return _dio.get(path, queryParameters: queryParameters);
    }
    await _waitForInvalidation(changedArea);
    final prefs = await SharedPreferences.getInstance();
    final key = await _cacheKey(path, queryParameters);
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final envelope = jsonDecode(raw) as Map<String, dynamic>;
        final savedAt = DateTime.parse(envelope['savedAt'] as String);
        final age = DateTime.now().toUtc().difference(savedAt);
        if (age < const Duration(hours: 24)) {
          if (age >= const Duration(minutes: 5)) {
            unawaited(_refreshCache(
                prefs, key, path, changedArea, queryParameters, raw));
          }
          return Response<dynamic>(
            data: envelope['data'],
            statusCode: 200,
            requestOptions: RequestOptions(path: path),
          );
        }
      } catch (_) {
        await prefs.remove(key);
      }
    }
    final response = await _dio.get(path, queryParameters: queryParameters);
    await _writeCache(prefs, key, response.data, changedArea);
    return response;
  }

  static Future<void> _refreshCache(
    SharedPreferences prefs,
    String key,
    String path,
    String changedArea,
    Map<String, dynamic>? queryParameters,
    String previous,
  ) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      await _writeCache(prefs, key, response.data, changedArea);
      final oldData = (jsonDecode(previous) as Map<String, dynamic>)['data'];
      if (jsonEncode(oldData) != jsonEncode(response.data)) {
        StateChangeNotifier.notify([changedArea]);
      }
    } catch (_) {
      // Keep the usable snapshot until its maximum age expires.
    }
  }

  static Future<void> _writeCache(SharedPreferences prefs, String key,
          Object? data, String changedArea) =>
      prefs.setString(
        key,
        jsonEncode({
          'savedAt': DateTime.now().toUtc().toIso8601String(),
          'data': data,
          'changedArea': changedArea,
        }),
      );

  static Future<void> invalidateCacheAreas(Iterable<String> areas) async {
    final wanted = areas
        .map((area) => area.trim())
        .where((area) => area.isNotEmpty)
        .toSet();
    if (wanted.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final sample = await _cacheKey('', null);
    final userPrefix = sample.substring(0, sample.lastIndexOf('.') + 1);
    final removals = <Future<bool>>[];
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(userPrefix))) {
      final raw = prefs.getString(key);
      if (raw == null) {
        continue;
      }
      try {
        final envelope = jsonDecode(raw) as Map<String, dynamic>;
        if (wanted.contains(envelope['changedArea'])) {
          removals.add(prefs.remove(key));
        }
      } catch (_) {
        removals.add(prefs.remove(key));
      }
    }
    await Future.wait(removals);
  }

  static void _scheduleFullCacheClear() {
    final future = clearCurrentUserCache().catchError((_) {});
    _pendingFullCacheClear = future;
    unawaited(future.whenComplete(() {
      if (identical(_pendingFullCacheClear, future)) {
        _pendingFullCacheClear = null;
      }
    }));
  }

  static void _scheduleAreaInvalidation(Iterable<String> areas) {
    final wanted = areas
        .map((area) => area.trim())
        .where((area) => area.isNotEmpty)
        .toSet();
    if (wanted.isEmpty) return;
    final future = invalidateCacheAreas(wanted).catchError((_) {});
    for (final area in wanted) {
      _pendingAreaInvalidations[area] = future;
    }
    unawaited(future.whenComplete(() {
      for (final area in wanted) {
        if (identical(_pendingAreaInvalidations[area], future)) {
          _pendingAreaInvalidations.remove(area);
        }
      }
    }));
  }

  static Future<void> _waitForInvalidation(String area) async {
    final full = _pendingFullCacheClear;
    if (full != null) await full;
    final scoped = _pendingAreaInvalidations[area];
    if (scoped != null) await scoped;
  }

  static Future<String> _cacheKey(
      String path, Map<String, dynamic>? queryParameters) async {
    final token = await getToken();
    var user = 'anonymous';
    if (token != null) {
      try {
        final part =
            token.split('.')[1].replaceAll('-', '+').replaceAll('_', '/');
        final normalized = part.padRight((part.length + 3) ~/ 4 * 4, '=');
        final claims = jsonDecode(utf8.decode(base64Decode(normalized)))
            as Map<String, dynamic>;
        user = (claims['sub'] ??
                claims[
                    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
                'anonymous')
            .toString();
      } catch (_) {}
    }
    final query = queryParameters == null ? '' : jsonEncode(queryParameters);
    final resource = base64Url.encode(utf8.encode('$path?$query'));
    return '$_cachePrefix.$user.$resource';
  }

  static Future<void> clearCurrentUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    final sample = await _cacheKey('', null);
    final userPrefix = sample.substring(0, sample.lastIndexOf('.') + 1);
    await Future.wait([
      for (final key in prefs.getKeys())
        if (key.startsWith(userPrefix)) prefs.remove(key),
    ]);
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    _tokenLoaded = true;
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<void> clearToken() async {
    await clearCurrentUserCache();
    _cachedToken = null;
    _tokenLoaded = true;
    await _storage.delete(key: 'jwt_token');
  }

  static Future<String?> getToken() async {
    if (_tokenLoaded) return _cachedToken;
    _cachedToken = await _storage.read(key: 'jwt_token');
    _tokenLoaded = true;
    return _cachedToken;
  }

  static String get _webBase {
    return _baseUrl.endsWith('/api')
        ? _baseUrl.substring(0, _baseUrl.length - 4)
        : _baseUrl;
  }

  static String get realtimeBaseUrl => _webBase;

  static String resolveMediaUrl(String path) {
    final uri = Uri.parse(path);
    return uri.hasScheme ? path : Uri.parse(_webBase).resolve(path).toString();
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

  static Future<String> get adminEncountersUrl async {
    final token = await _storage.read(key: 'jwt_token');
    final base = '$_webBase/admin/encounters.html';
    return token != null ? '$base?token=${Uri.encodeComponent(token)}' : base;
  }

  static Future<bool> isAdmin() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final claims = jsonDecode(utf8.decode(base64Decode(payload)))
          as Map<String, dynamic>;
      // ASP.NET Core serialises ClaimTypes.Role as this URI key
      final role = claims[
              'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
          claims['role'];
      return role == 'Admin';
    } catch (_) {
      return false;
    }
  }
}
