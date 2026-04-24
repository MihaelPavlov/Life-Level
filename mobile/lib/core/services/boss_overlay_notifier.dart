import 'dart:async';

/// Fired when the region trail wants to open the shell's Boss overlay (for
/// a world-zone boss that was just lazy-spawned by the backend). The shell
/// listens and sets `_bossOpen = true` exactly like the ring menu path.
///
/// No payload — the BossScreen re-fetches its own list via `bossListProvider`.
class BossOverlayNotifier {
  BossOverlayNotifier._();
  static final StreamController<void> _controller =
      StreamController<void>.broadcast();
  static Stream<void> get stream => _controller.stream;
  static void notify() => _controller.add(null);
}
