import 'dart:async';
import '../api/api_client.dart';

/// Broadcast signal that the world zone state has changed (travel distance added,
/// zone completed, etc.) and any open WorldMapScreen should reload its data.
class WorldZoneRefreshNotifier {
  WorldZoneRefreshNotifier._();

  static final _controller = StreamController<void>.broadcast();
  static Timer? _pending;

  static Stream<void> get stream => _controller.stream;

  /// A mutation can send a response hint, a floor event, and a local refresh
  /// together. Clear the persisted world snapshot before listeners refetch.
  static void notify() {
    _pending?.cancel();
    _pending = Timer(const Duration(milliseconds: 100), () async {
      _pending = null;
      try {
        await ApiClient.invalidateCacheAreas(const ['world']);
      } catch (_) {
        // In-memory providers should still retry if local storage is broken.
      }
      _controller.add(null);
    });
  }
}
