import 'dart:async';

import '../../features/activity/models/activity_models.dart';

/// Payload broadcast when a character levels up. [unlocks] carries real
/// per-level rewards (items, zones, stat points) when available from the
/// triggering API response; consumers that don't have unlocks (e.g. map
/// debug panel, profile refresh) can pass null.
class LevelUpEvent {
  final int newLevel;
  final LevelUpUnlocks? unlocks;

  const LevelUpEvent(this.newLevel, {this.unlocks});
}

/// Global notifier for level-up events. MainShell listens and shows the
/// overlay from the root navigator.
class LevelUpNotifier {
  LevelUpNotifier._();

  static final _controller = StreamController<LevelUpEvent>.broadcast();

  static Stream<LevelUpEvent> get stream => _controller.stream;

  static void notify(int newLevel, {LevelUpUnlocks? unlocks}) =>
      _controller.add(LevelUpEvent(newLevel, unlocks: unlocks));
}
