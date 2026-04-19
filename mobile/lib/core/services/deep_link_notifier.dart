import 'dart:async';

/// Global notifier for deep-link URIs that originate outside the MainShell's
/// own `uriLinkStream` subscription — for example, notification taps from
/// Firebase Cloud Messaging.
///
/// Fire with: DeepLinkNotifier.notify(Uri.parse('lifelevel://boss/123'))
/// MainShell listens on this stream and hands the URI to its existing
/// `_handleDeepLink(Uri)` routine, so notification-tap routing reuses the
/// same logic as the OAuth callback flow.
class DeepLinkNotifier {
  DeepLinkNotifier._();

  static final _controller = StreamController<Uri>.broadcast();

  static Stream<Uri> get stream => _controller.stream;

  static void notify(Uri uri) => _controller.add(uri);
}
