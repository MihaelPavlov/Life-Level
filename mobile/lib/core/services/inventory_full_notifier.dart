import 'dart:async';
import '../../features/activity/models/activity_models.dart';

/// Global notifier for inventory-full events.
/// Fire with [InventoryFullNotifier.notify] when an item grant was blocked
/// because the character's inventory was at capacity.
/// [MainShell] subscribes and shows [InventoryFullOverlay].
class InventoryFullNotifier {
  InventoryFullNotifier._();

  static final _controller = StreamController<BlockedItemInfo>.broadcast();

  static Stream<BlockedItemInfo> get stream => _controller.stream;

  static void notify(BlockedItemInfo item) => _controller.add(item);
}
