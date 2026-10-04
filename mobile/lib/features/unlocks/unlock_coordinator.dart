import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/app_motion.dart';
import '../../core/services/world_zone_refresh_notifier.dart';
import '../../core/motion/reward_fx.dart';
import '../../core/widgets/app_icon_image.dart';
import 'models/unlock_catalog.dart';
import 'models/unlock_models.dart';
import 'providers/unlocks_provider.dart';
import 'tour/feature_tour.dart';
import 'tour/tour_target.dart';
import 'tour/unlock_tour_runner.dart';
import 'widgets/unlock_ceremony.dart';

/// Tour target id of the slot an unlocked feature lives in (hub tile, tab,
/// Map button, chip), used for the icon's flight after the ceremony.
String unlockSlotTargetId(String key) => switch (key) {
      UnlockKeys.map => 'shell.mapOrb',
      UnlockKeys.gear => 'slot.gear',
      UnlockKeys.modes || UnlockKeys.delve => 'slot.modes',
      _ => 'slot.$key',
    };

/// Plays unlock ceremonies one at a time and starts the Home tour after
/// onboarding. Sits in the shell; the shell tells it when it may interrupt
/// (no level-up screen, no feature open) and how to open a feature.
class UnlockCoordinator extends ConsumerStatefulWidget {
  /// True when nothing else is on screen that a ceremony would cover.
  final bool Function() canInterrupt;

  /// Opens the feature's screen. For Home, Map, Gear and Modes (which live in
  /// the shell rather than on a screen of their own) it also runs the tour.
  final Future<void> Function(String key) openFeature;

  final Widget child;

  const UnlockCoordinator({
    super.key,
    required this.canInterrupt,
    required this.openFeature,
    required this.child,
  });

  @override
  ConsumerState<UnlockCoordinator> createState() => _UnlockCoordinatorState();
}

class _UnlockCoordinatorState extends ConsumerState<UnlockCoordinator> {
  bool _busy = false;
  Timer? _retry;

  /// The Home tour is offered once per session; if it can't run (nothing to
  /// point at yet) it waits for the next launch instead of retrying.
  bool _homeTried = false;
  StreamSubscription<void>? _worldSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pump());
    // Reaching a zone or spawning a boss can unlock Region Chests / Bosses.
    _worldSub = WorldZoneRefreshNotifier.stream
        .listen((_) => ref.read(unlocksProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _retry?.cancel();
    _worldSub?.cancel();
    super.dispose();
  }

  void _schedule([Duration delay = const Duration(seconds: 2)]) {
    _retry?.cancel();
    _retry = Timer(delay, _pump);
  }

  Future<void> _pump() async {
    if (!mounted || _busy) return;
    final snapshot = ref.read(unlocksSnapshotProvider);
    if (snapshot.isFallback) return;
    final homeTour = !_homeTried && snapshot.isFresh(UnlockKeys.home);
    final pending = snapshot.pendingCeremonies;
    if (!homeTour && pending.isEmpty) return;
    if (!_free()) {
      _schedule();
      return;
    }

    _busy = true;
    try {
      if (homeTour) {
        _homeTried = true;
        await widget.openFeature(UnlockKeys.home);
      } else {
        unlockMomentRunning = true;
        try {
          await _moment(pending);
        } finally {
          unlockMomentRunning = false;
        }
      }
    } finally {
      _busy = false;
    }
    if (mounted) _schedule(const Duration(milliseconds: 900));
  }

  /// Nothing else on screen: no level-up, overlay, sheet or running tour.
  bool _free() => !FeatureTour.isRunning && widget.canInterrupt();

  /// One moment's unlocks (the server releases at most one level's worth),
  /// strictly one after the other: ceremony 1 of 2, its tour if Show me was
  /// picked, the "1 more unlock" bridge, then ceremony 2 of 2. Nothing starts
  /// before the step before it has finished.
  Future<void> _moment(List<UnlockState> pending) async {
    final queue = [
      for (final u in pending)
        if (kUnlockCatalog[u.key] != null) kUnlockCatalog[u.key]!,
    ];
    final notifier = ref.read(unlocksProvider.notifier);
    for (final u in pending) {
      if (kUnlockCatalog[u.key] == null) await notifier.markSeen(u.key);
    }
    for (var i = 0; i < queue.length; i++) {
      if (!mounted) return;
      if (i > 0) {
        // A Show me tour (or the screen it opened) has to be over first.
        await _waitUntilFree();
        if (!mounted) return;
        await showUnlockBridge(context, queue[i],
            remaining: queue.length - i);
        if (!mounted) return;
      }
      await _ceremony(queue[i], queue, i);
    }
  }

  Future<void> _waitUntilFree() async {
    // The feature's first-visit tour starts a moment after its screen opens.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    while (mounted && !_free()) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _ceremony(UnlockMeta meta, List<UnlockMeta> queue, int index) async {
    final notifier = ref.read(unlocksProvider.notifier);
    unlockCeremonyShowing = true;
    bool showMe;
    try {
      showMe = await showUnlockCeremony(context, meta,
          queue: queue, index: index);
    } finally {
      unlockCeremonyShowing = false;
    }
    await notifier.markSeen(meta.key);
    if (!mounted) return;
    await _flyToSlot(meta);
    if (!mounted || !showMe) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) await widget.openFeature(meta.key);
  }

  /// The feature's icon arcs from the middle of the screen into its slot.
  Future<void> _flyToSlot(UnlockMeta meta) async {
    final id = unlockSlotTargetId(meta.key);
    final ctx = TourTargets.contextOf(id);
    if (ctx != null && ctx.mounted && Scrollable.maybeOf(ctx) != null) {
      await Scrollable.ensureVisible(ctx,
          alignment: .5,
          duration:
              AppMotion.duration(context, const Duration(milliseconds: 250)));
    }
    final to = TourTargets.rectOf(id);
    if (to == null || !mounted) return;
    final size = MediaQuery.sizeOf(context);
    final from = Offset(size.width / 2, size.height * .38);
    await RewardFx.fly(
      context,
      child: AppIconImage(meta.icon, size: 60),
      from: from,
      to: to.center,
      lift: -80,
      endScale: .5,
      duration: const Duration(milliseconds: 720),
    );
    if (!mounted) return;
    RewardFx.ring(context, to.center, meta.color, maxRadius: 40);
    RewardFx.burst(context, to.center, meta.color, count: 16, distance: 36);
  }

  @override
  Widget build(BuildContext context) {
    // A short wait lets a level-up from the same workout claim the screen
    // first: workout → level up → unlocks.
    ref.listen<UnlocksSnapshot>(unlocksSnapshotProvider,
        (_, __) => _schedule(const Duration(milliseconds: 1200)));
    return widget.child;
  }
}
