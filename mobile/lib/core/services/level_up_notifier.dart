import 'dart:async';

/// Global notifier for level-up events.
/// Any screen that receives XP calls [LevelUpNotifier.notify] with the new level.
/// MainShell listens and shows the overlay from the root navigator.
class LevelUpNotifier {
  LevelUpNotifier._();

  static final _controller = StreamController<int>.broadcast();

  static Stream<int> get stream => _controller.stream;

  static void notify(int newLevel) => _controller.add(newLevel);
}
