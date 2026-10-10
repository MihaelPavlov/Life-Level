import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/shell/boot/boot_readiness.dart';
import '../../../core/widgets/reward_moment/reward_moment.dart';
import '../../character/providers/character_provider.dart';
import '../models/unlock_catalog.dart';
import '../providers/unlocks_provider.dart';
import 'feature_tour.dart';
import 'tours/unlock_tours.dart';

/// While true, first-visit tours wait (an unlock ceremony is on screen).
bool unlockCeremonyShowing = false;

/// While true, a moment's unlocks are playing (ceremonies, their tours and
/// the bridge between them). Level-ups wait so they never cut into the queue.
bool unlockMomentRunning = false;

/// Replays from Profile → Tutorials. The shell opens the feature; a screen
/// that opens on its own picks up [pendingKey] and runs the tour again.
abstract final class UnlockReplay {
  static final _controller = StreamController<String>.broadcast();
  static Stream<String> get stream => _controller.stream;

  /// Set by the shell just before it opens a feature for a replay.
  static String? pendingKey;

  static void request(String key) => _controller.add(key);
}

/// Runs the tour for [key]. The first time it's finished (or skipped) the
/// feature is marked toured, which pays the tour coins once. A [replay] from
/// Profile → Tutorials pays nothing and changes nothing.
Future<TourOutcome> runUnlockTour(
  BuildContext context,
  WidgetRef ref,
  String key, {
  bool replay = false,
}) {
  final meta = kUnlockCatalog[key];
  if (meta == null) return Future.value(TourOutcome.aborted);
  return FeatureTour.run(
    context,
    name: meta.name,
    color: meta.color,
    steps: tourStepsFor(key),
    onComplete: (_) async {
      if (replay) return 0;
      final coins = await ref.read(unlocksProvider.notifier).markToured(key);
      if (coins > 0) {
        unawaited(ref.read(characterProfileProvider.notifier).refresh());
      }
      return coins;
    },
  );
}

/// Runs [unlockKey]'s tour the first time this screen is shown after the
/// feature unlocked (whether the player chose Show me or Later).
class TourOnFirstVisit extends ConsumerStatefulWidget {
  final String unlockKey;
  final Widget child;

  const TourOnFirstVisit({
    super.key,
    required this.unlockKey,
    required this.child,
  });

  @override
  ConsumerState<TourOnFirstVisit> createState() => _TourOnFirstVisitState();
}

class _TourOnFirstVisitState extends ConsumerState<TourOnFirstVisit> {
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    // Give the screen's entrance animation and first load time to settle.
    Future<void>.delayed(const Duration(milliseconds: 550), _maybeRun);
  }

  Future<void> _maybeRun() async {
    if (!mounted || _tried) return;
    if (bootLoaderShowing ||
        unlockCeremonyShowing ||
        FeatureTour.isRunning ||
        RewardMoment.isBlockingMomentShowing) {
      Future<void>.delayed(const Duration(milliseconds: 600), _maybeRun);
      return;
    }
    final replay = UnlockReplay.pendingKey == widget.unlockKey;
    if (replay) UnlockReplay.pendingKey = null;
    final snapshot = ref.read(unlocksSnapshotProvider);
    if (!replay && !snapshot.isFresh(widget.unlockKey)) return;
    _tried = true;
    await runUnlockTour(context, ref, widget.unlockKey, replay: replay);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
