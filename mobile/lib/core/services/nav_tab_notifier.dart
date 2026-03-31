import 'dart:async';

/// Broadcast signal to switch the bottom nav to a specific tab by id.
/// Fire with: NavTabNotifier.switchTo('quests')
class NavTabNotifier {
  NavTabNotifier._();

  static final _controller = StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  static void switchTo(String tabId) => _controller.add(tabId);
}
