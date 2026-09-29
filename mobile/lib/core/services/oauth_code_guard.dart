/// Remembers OAuth authorization codes that have already been handed to the
/// backend. `AppLinks().getInitialLink()` keeps returning the URI that
/// cold-started the app for the whole process lifetime, so without this the
/// shell would try to spend a code onboarding already used.
class OAuthCodeGuard {
  OAuthCodeGuard._();

  static final _seen = <String>{};

  /// True the first time [code] is seen; false for every repeat.
  static bool claim(String code) => _seen.add(code);
}
