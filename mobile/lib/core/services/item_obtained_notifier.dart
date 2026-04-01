import 'dart:async';
import '../../features/items/models/item_models.dart';

/// Global notifier for item-obtained events.
/// Any code path that grants an item calls [ItemObtainedNotifier.notify].
/// MainShell listens and shows the item popup overlay from the root navigator.
class ItemObtainedNotifier {
  ItemObtainedNotifier._();

  static final _controller = StreamController<ItemDto>.broadcast();

  static Stream<ItemDto> get stream => _controller.stream;

  static void notify(ItemDto item) => _controller.add(item);
}
