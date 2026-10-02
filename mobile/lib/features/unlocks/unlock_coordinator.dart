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
    if (FeatureTour.isRunning || !widget.canInterrupt()) {
      _schedule();
      return;
    }

    _busy = true;
    try {
      if (homeTour) {
        _homeTried = true;
        await widget.openFeature(UnlockKeys.home);
      } else {
        await _ceremony(pending.first);
      }
    } finally {
      _busy = false;
    }
    if (mounted) _schedule(const Duration(milliseconds: 900));
  }

  Future<void> _ceremony(UnlockState u) async {
    final meta = kUnlockCatalog[u.key];
    final notifier = ref.read(unlocksProvider.notifier);
    if (meta == null) {
      await notifier.markSeen(u.key);
      return;
    }
    unlockCeremonyShowing = true;
    bool showMe;
    try {
      showMe = await showUnlockCeremony(context, meta);
    } finally {
      unlockCeremonyShowing = false;
    }
    await notifier.markSeen(u.key);
    if (!mounted) return;
    await _flyToSlot(meta);
    if (!mounted || !showMe) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) await widget.openFeature(u.key);
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
    ref.listen<UnlocksSnapshot>(unlocksSnapshotProvider, (_, __) => _pump());
    return widget.child;
  }
}
