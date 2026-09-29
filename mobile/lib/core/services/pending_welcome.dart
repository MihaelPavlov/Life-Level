/// A one-shot message the shell shows when it first mounts — used by
/// onboarding to greet the new hero on Home ("Welcome, Ranger Kael…").
class PendingWelcome {
  PendingWelcome._();

  static String? _message;

  static void set(String message) => _message = message;

  /// Returns the message once, then clears it.
  static String? take() {
    final m = _message;
    _message = null;
    return m;
  }
}
