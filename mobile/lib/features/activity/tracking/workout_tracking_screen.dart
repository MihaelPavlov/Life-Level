import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../integrations/providers/integrations_provider.dart';
import '../../map/widgets/encounter_intercept_sheet.dart';
import '../activity_result_sheet.dart';
import '../models/activity_models.dart';
import '../providers/activity_provider.dart';
import 'workout_tracker.dart';

class WorkoutTrackingScreen extends ConsumerStatefulWidget {
  const WorkoutTrackingScreen({super.key});

  @override
  ConsumerState<WorkoutTrackingScreen> createState() =>
      _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends ConsumerState<WorkoutTrackingScreen> {
  ActivityType _selected = ActivityType.running;
  Timer? _ticker;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracker = ref.watch(workoutTrackerProvider);
    final integration = ref.watch(integrationSyncProvider);
    final hasIntegration = integration.isHealthConnected ||
        integration.isStravaConnected ||
        integration.isGarminConnected;
    final session = tracker.current;
    final active = session?.isRunning ?? false;
    final seconds = session?.activeSeconds ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Track workout'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!tracker.ready)
              const Center(child: CircularProgressIndicator())
            else if (session == null) ...[
              const Text('Choose your activity',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 16),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final type in ActivityType.values)
                    ChoiceChip(
                      label: Text('${type.emoji}  ${type.displayName}'),
                      selected: type == _selected,
                      onSelected: (_) => setState(() => _selected = type),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                const {
                  ActivityType.running,
                  ActivityType.walking,
                  ActivityType.hiking,
                  ActivityType.cycling
                }.contains(_selected)
                    ? 'Phone GPS measures outdoor distance. A session with usable GPS can earn game progress.'
                    : 'This timer saves your session. Wearable workout data is required for game progress.',
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 25),
              _action(
                  'Start workout',
                  Icons.play_arrow_rounded,
                  hasIntegration || !integration.statusLoaded || _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            await tracker.start(_selected);
                          } catch (e) {
                            if (mounted) {
                              setState(() => _message = e.toString());
                            }
                          }
                          if (mounted) setState(() => _busy = false);
                        }),
              if (hasIntegration)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Your connected tracker handles workout import.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
            ] else ...[
              Text(session.type.displayName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 20),
              Text(_clock(seconds),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 56,
                      fontWeight: FontWeight.w800)),
              if (session.usesGps) ...[
                const SizedBox(height: 12),
                Text('${(session.distanceMeters / 1000).toStringAsFixed(2)} km',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 26)),
                const SizedBox(height: 7),
                Text(_pace(session.distanceMeters, seconds),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text(
                    'Rewards need at least 2 minutes, 100 m, and a usable GPS signal for half the session.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                if (active && !tracker.gpsAvailable)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                        'GPS unavailable. You can finish and save this session without rewards.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
              ],
              const SizedBox(height: 28),
              _action(
                  active ? 'Pause' : 'Resume',
                  active ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          if (active) {
                            await tracker.pause();
                          } else {
                            await tracker.resume();
                          }
                          if (mounted) setState(() => _busy = false);
                        }),
              const SizedBox(height: 12),
              _action(
                  'Finish workout',
                  Icons.stop_rounded,
                  _busy || seconds < 1
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          final result = await tracker.finish();
                          if (!context.mounted) return;
                          setState(() {
                            _busy = false;
                            _message = result == null
                                ? 'Workout saved on this phone. It will sync when online.'
                                : result.gpsMeasured
                                    ? 'Workout saved. Game progress updated.'
                                    : 'Session saved without game rewards.';
                          });
                          if (result?.reward != null) {
                            applyActivityResultEffects(ref, result!.reward!);
                            ref.invalidate(trackedSessionsProvider);
                            showAppBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) =>
                                  ActivityResultSheet(result: result.reward!),
                            );
                            final encounter = result.reward!.activeEncounter;
                            if (encounter != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!context.mounted) return;
                                showAppBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  isDismissible: !encounter.isBlocker,
                                  enableDrag: !encounter.isBlocker,
                                  builder: (_) => EncounterInterceptSheet(
                                    encounter: encounter,
                                    destinationZoneName: 'your destination',
                                  ),
                                );
                              });
                            }
                          } else if (result != null) {
                            ref.invalidate(trackedSessionsProvider);
                          }
                        }),
            ],
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            if (tracker.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(tracker.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback? onPressed) =>
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue, foregroundColor: Colors.white),
        ),
      );

  String _clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _pace(double meters, int seconds) {
    if (meters < 10 || seconds < 1) return 'Pace —';
    final secPerKm = seconds / (meters / 1000);
    return 'Pace ${(secPerKm ~/ 60)}:${(secPerKm % 60).floor().toString().padLeft(2, '0')} / km';
  }
}
