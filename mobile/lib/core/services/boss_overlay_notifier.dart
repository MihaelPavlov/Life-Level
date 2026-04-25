import 'dart:async';

/// Intent payload for opening the shell's Boss overlay.
///
/// `bossId == null` lands on the boss list (legacy region-trail behaviour).
/// A non-null id asks `BossScreen` to auto-open the battle view for that
/// specific boss once the list resolves — used by the home portal's
/// "Fight →" CTAs so the user lands directly in the fight.
class BossOpenIntent {
  final String? bossId;
  const BossOpenIntent({this.bossId});
}

/// Fired when something wants to open the shell's Boss overlay (for example
/// a region-trail world-zone boss that was just lazy-spawned by the backend,
/// or the home portal's boss-zone CTA). The shell listens, flips
/// `_bossOpen = true`, and pipes the intent's `bossId` into `BossScreen`.
class BossOverlayNotifier {
  BossOverlayNotifier._();
  static final StreamController<BossOpenIntent> _controller =
      StreamController<BossOpenIntent>.broadcast();
  static Stream<BossOpenIntent> get stream => _controller.stream;

  /// Open the overlay on the list view (no preselection).
  static void notify() => _controller.add(const BossOpenIntent());

  /// Open the overlay AND auto-open the battle for [bossId].
  static void notifyForBoss(String bossId) =>
      _controller.add(BossOpenIntent(bossId: bossId));
}
