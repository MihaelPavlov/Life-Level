import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../models/integration_models.dart';

class StravaService {
  static const _authBase = 'https://www.strava.com/oauth/authorize';
  static const _redirectUri = 'lifelevel://oauth/strava';
  static const _clientId = '218444';
  static const _scope = 'activity:read_all';

  String get authorizationUrl => authorizationUrlFor(_redirectUri);

  String get webRedirectUri => Uri.base
      .replace(path: '/auth.html', query: null, fragment: null)
      .toString();

  String authorizationUrlFor(String redirectUri, {bool forceApproval = false}) =>
      '$_authBase?client_id=$_clientId'
      '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
      '&response_type=code'
      '&approval_prompt=${forceApproval ? 'force' : 'auto'}'
      '&scope=$_scope';

  /// Starts OAuth and returns the authorization result on web. Native apps
  /// resume through their `lifelevel://` deep link, so they return null here.
  Future<StravaAuthorizationResult?> authorize({bool forceApproval = false}) async {
    if (kIsWeb) {
      final redirectUri = webRedirectUri;
      final callback = await FlutterWebAuth2.authenticate(
        url: authorizationUrlFor(redirectUri, forceApproval: forceApproval),
        callbackUrlScheme: Uri.parse(redirectUri).scheme,
      );
      final callbackUri = Uri.parse(callback);
      final error = callbackUri.queryParameters['error'];
      if (error != null) {
        throw StateError('Strava authorization was declined.');
      }
      final code = callbackUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw StateError('Strava did not return an authorization code.');
      }
      return StravaAuthorizationResult(code, redirectUri);
    }

    await launchUrl(
      Uri.parse(authorizationUrlFor(_redirectUri, forceApproval: forceApproval)),
      mode: LaunchMode.externalApplication,
    );
    return null;
  }

  Future<StravaStatusDto> getStatus() async {
    try {
      final response =
          await ApiClient.instance.get('/integrations/strava/status');
      return StravaStatusDto.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return const StravaStatusDto(isConnected: false);
    }
  }

  Future<StravaStatusDto> connect(String code, {String? redirectUri}) async {
    final response = await ApiClient.instance.post(
      '/integrations/strava/connect',
      data: {'code': code, 'redirectUri': redirectUri ?? _redirectUri},
    );
    return StravaStatusDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> disconnect() async {
    await ApiClient.instance.delete('/integrations/strava/disconnect');
  }
}

class StravaAuthorizationResult {
  final String code;
  final String redirectUri;

  const StravaAuthorizationResult(this.code, this.redirectUri);
}
