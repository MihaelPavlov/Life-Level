import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/integrations/services/strava_service.dart';

void main() {
  test('builds an authorization URL with the supplied web redirect URI', () {
    const redirectUri = 'http://localhost:5000/auth.html';

    final uri = Uri.parse(StravaService().authorizationUrlFor(redirectUri));

    expect(uri.host, 'www.strava.com');
    expect(uri.path, '/oauth/authorize');
    expect(uri.queryParameters['client_id'], '218444');
    expect(uri.queryParameters['redirect_uri'], redirectUri);
    expect(uri.queryParameters['response_type'], 'code');
    expect(uri.queryParameters['scope'], 'activity:read_all');
  });
}
