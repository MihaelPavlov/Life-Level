import 'dart:async';

/// Data-free invalidation hints from mutation responses and SignalR.
class StateChangeNotifier {
  static final _changes = StreamController<Set<String>>.broadcast();
  static Stream<Set<String>> get stream => _changes.stream;

  static void notify(Iterable<String> areas) {
    final values = areas.where((area) => area.isNotEmpty).toSet();
    if (values.isNotEmpty) _changes.add(values);
  }
}
