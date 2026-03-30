import 'dart:async';

/// Broadcast signal that the world zone state has changed (travel distance added,
/// zone completed, etc.) and any open WorldMapScreen should reload its data.
class WorldZoneRefreshNotifier {
  WorldZoneRefreshNotifier._();

  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() => _controller.add(null);
}
