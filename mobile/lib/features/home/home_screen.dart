import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../character/providers/character_provider.dart';
import '../integrations/providers/integrations_provider.dart';
import '../sync/providers/pending_workouts_provider.dart';
import '../sync/pull_import_flow.dart';
import '../sync/widgets/pull_to_import.dart';
import '../sync/widgets/sync_status_pill.dart';
import '../tutorial/providers/tutorial_provider.dart';
import '../tutorial/tutorial_controller.dart';
import 'cards/home_adventure_hub.dart';
import 'cards/home_happening_now.dart';
import 'cards/home_hero_stage.dart';
import 'cards/home_log_workout_cta.dart';
import 'cards/home_seasonal_event_row.dart';
import 'cards/home_xp_storm_banner.dart';

/// Home tab scaffold: hero stage, Adventure Hub and Happening now.
///
/// The journey (the old map card) lives behind the Map button in the tab
/// bar. Syncing is a pull: drag Home down to check the pending-workout queue
/// and import what came in (see `features/sync/`).
/// TESTING: keep "Log workout" pinned at the bottom of Home even when a
/// tracker is connected. Set to false to show it only without an integration.
const kAlwaysShowLogWorkout = true;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // LL-035: GlobalKeys attached to the Home coach-mark targets. The
  // tutorial controller reads their global rects to place floating bubbles.
  final _xpCardKey = GlobalKey();
  bool _tutorialKeysRegistered = false;
  bool _flowRunning = false;

  late final TutorialController _tutorial;

  @override
  void initState() {
    super.initState();
    _tutorial = ref.read(tutorialControllerProvider);
    // Show the pending pill as soon as Home opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingWorkoutsProvider.notifier).checkQuietly();
    });
  }

  @override
  void dispose() {
    // `ref` is gone by now; use the controller read in initState.
    _tutorial.unregisterKey('xpCard');
    super.dispose();
  }

  Future<void> _runFlow() async {
    if (_flowRunning) return;
    _flowRunning = true;
    try {
      await runPullImportFlow(context, ref);
    } finally {
      _flowRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final pending = ref.watch(pendingWorkoutsProvider);
    final integrations = ref.watch(integrationSyncProvider);
    final hasIntegration = integrations.isHealthConnected ||
        integrations.isStravaConnected ||
        integrations.isGarminConnected;
    final showLogWorkout = kAlwaysShowLogWorkout || !hasIntegration;
    final topPad = MediaQuery.of(context).padding.top;

    if (!_tutorialKeysRegistered) {
      _tutorialKeysRegistered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = ref.read(tutorialControllerProvider);
        c.registerKey('xpCard', _xpCardKey);
      });
    }

    // XP Storm & Seasonal event are scaffold-only — they render nothing
    // until LL-001 / LL-012 land a real feed and start returning non-null
    // state here.
    const xpStormState = null;
    const seasonalState = null;

    return Container(
      color: AppColors.backgroundAlt,
      child: Stack(
        children: [
          PullToImport(
            pendingCount: pending.pendingCount,
            busy: pending.checking || pending.importing,
            onTrigger: _runFlow,
            topInset: topPad + 20,
            child: SingleChildScrollView(
              physics: PullToImport.physics,
              // Clear the raised Map button (and the "Log workout" CTA
              // when it shows).
              padding: EdgeInsets.only(bottom: showLogWorkout ? 110 : 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      KeyedSubtree(
                        key: _xpCardKey,
                        child: HomeHeroStage(profile: profile),
                      ),
                      // Under the header row, between the mount and weapon
                      // cards: "2 new workouts · pull down" / "Synced 2m ago".
                      Positioned(
                        top: topPad + 66,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SyncStatusPill(
                            pendingCount: pending.pendingCount,
                            lastCheckedAt: pending.lastCheckedAt,
                            busy: pending.checking,
                            onTap: _runFlow,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const HomeAdventureHub(),
                  const HomeXpStormBanner(state: xpStormState),
                  const HomeHappeningNow(),
                  const HomeSeasonalEventRow(state: seasonalState),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Without a tracker, logging by hand is the way in (and always
          // while testing, see kAlwaysShowLogWorkout).
          if (showLogWorkout)
            // Lifted so the raised Map button doesn't cover it.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: HomeLogWorkoutCta(),
            ),
        ],
      ),
    );
  }
}
