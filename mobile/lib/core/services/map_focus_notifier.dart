import 'dart:async';

/// Broadcast signal to re-focus the map on a specific world zone.
///
/// Fire with a world-zone id — `MapScreen` re-centers on it.
/// Fire with `null` — `MapScreen` falls back to the user's current/destination zone.
/// Tab switch is done separately via `NavTabNotifier` so callers can switch
/// without focusing, or focus without switching.
class MapFocusNotifier {
  MapFocusNotifier._();

  static final _controller = StreamController<String?>.broadcast();

  static Stream<String?> get stream => _controller.stream;

  static void focus(String? worldZoneId) => _controller.add(worldZoneId);
}
