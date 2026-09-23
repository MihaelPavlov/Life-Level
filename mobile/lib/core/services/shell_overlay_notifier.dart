import 'dart:async';

/// Fired when something outside `MainShell`'s own widget tree (e.g. the
/// Home screen's Adventure Hub tiles) wants to open one of the shell's ring
/// overlay screens — Guild, Quests, Titles, Season, Talents, or Achievements — as an in-shell overlay
/// (bottom nav bar stays visible) instead of pushing it as a separate
/// full-screen route.
class ShellOverlayNotifier {
  ShellOverlayNotifier._();
  static final StreamController<String> _controller =
      StreamController<String>.broadcast();
  static Stream<String> get stream => _controller.stream;

  /// [id] is an overlay id such as 'guild', 'quests', 'titles', 'season',
  /// 'talents', or 'achievements'.
  static void open(String id) => _controller.add(id);
}
