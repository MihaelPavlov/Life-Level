import '../../../core/api/api_client.dart';
import '../models/integration_models.dart';

class StravaService {
  static const _authBase = 'https://www.strava.com/oauth/authorize';
  static const _redirectUri = 'lifelevel://oauth/strava';
  static const _clientId = '218444';
  static const _scope = 'activity:read_all';

  String get authorizationUrl =>
      '$_authBase?client_id=$_clientId'
      '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
      '&response_type=code'
      '&approval_prompt=auto'
      '&scope=$_scope';

  Future<StravaStatusDto> getStatus() async {
    try {
      final response = await ApiClient.instance.get('/integrations/strava/status');
      return StravaStatusDto.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return const StravaStatusDto(isConnected: false);
    }
  }

  Future<StravaStatusDto> connect(String code) async {
    final response = await ApiClient.instance.post(
      '/integrations/strava/connect',
      data: {'code': code, 'redirectUri': _redirectUri},
    );
    return StravaStatusDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> disconnect() async {
    await ApiClient.instance.delete('/integrations/strava/disconnect');
  }
}
