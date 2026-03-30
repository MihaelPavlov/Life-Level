import 'dart:async';

/// Broadcast signal fired when the user taps the Map tab.
/// MapScreen resets its cached zone and reloads so the crossroads
/// (or any zone change) is reflected immediately.
class MapTabNotifier {
  MapTabNotifier._();

  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() => _controller.add(null);
}
