import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/reward_fx.dart';
import '../../core/shell/shell_anchors.dart';
import '../../core/widgets/app_icon_image.dart';
import '../../core/widgets/app_toast.dart';
import '../boss/replay/home_boss_replay.dart';
import '../onboarding/widgets/activity_visuals.dart';
import 'models/pending_models.dart';
import 'providers/pending_workouts_provider.dart';
import 'services/pending_workouts_service.dart';
import 'widgets/import_review_sheet.dart';

/// What a pull on Home (or a tap on the pending pill) does:
/// check the queue → review sheet → import → rewards land on the hero.
///
/// Returns once everything, including the celebration, has finished.
Future<void> runPullImportFlow(BuildContext context, WidgetRef ref,
    {bool refreshStrava = true}) async {
  final notifier = ref.read(pendingWorkoutsProvider.notifier);
  if (ref.read(pendingWorkoutsProvider).checking ||
      ref.read(pendingWorkoutsProvider).importing) {
    return;
  }

  final PendingWorkoutList list;
  try {
    list = await notifier.check(refreshStrava: refreshStrava);
  } on StravaStageException catch (e) {
    if (!context.mounted) return;
    AppToast.error(context, 'Strava sync failed', detail: e.message);
    return;
  } catch (_) {
    if (!context.mounted) return;
    final waiting = ref.read(pendingWorkoutsProvider).pendingCount;
    AppToast.warning(
      context,
      'You’re offline',
      detail: waiting > 0
          ? 'Your $waiting workout${waiting == 1 ? ' is' : 's are'} safe in the queue. Pull again when you’re back online.'
          : 'Pull again when you’re back online.',
      icon: Icons.wifi_off_rounded,
    );
    return;
  }
  if (!context.mounted) return;

  if (list.items.isEmpty) {
    AppToast.info(
      context,
      'You’re up to date',
      detail: 'No new workouts.',
      icon: Icons.check_circle_outline_rounded,
    );
    return;
  }

  final choice = await showImportReviewSheet(context, list);
  if (!context.mounted) return;
  final rejectedIds = list.rejected.map((w) => w.id).toList();
  if (rejectedIds.isNotEmpty) {
    try {
      await notifier.acknowledgeRejected(rejectedIds);
    } catch (_) {
      // Keep them unacknowledged so the player sees them on the next sync.
    }
  }
  if (!context.mounted) return;
  if (choice == null || choice.ids.isEmpty) {
    if (list.pending.isEmpty) return;
    final n = ref.read(pendingWorkoutsProvider).pendingCount;
    AppToast.info(
      context,
      'Saved for later',
      detail:
          '$n workout${n == 1 ? ' waits' : 's wait'} in your queue. They still count for the day you trained.',
      icon: Icons.schedule_rounded,
    );
    return;
  }

  final ImportPendingResult result;
  try {
    result = await notifier.import(choice.ids);
  } catch (_) {
    if (!context.mounted) return;
    AppToast.error(
      context,
      'Import failed',
      detail: 'Nothing was lost. Pull down to try again.',
    );
    return;
  }
  if (!context.mounted) return;
  await playImportCelebration(context, result,
      from: choice.from, showToast: false);
  if (!context.mounted || result.imported.isEmpty) return;
  // Imported workouts hit the boss too. When there is an exchange to play,
  // its recap carries the import summary; otherwise the usual toast shows.
  requestBossReplay(
    summary: importSummary(result),
    orElse: () {
      if (context.mounted) showImportToast(context, result);
    },
  );
}

/// Workout icons fly into the hero, XP and stat gains float up, the avatar's
/// XP ring pulses and the km land on the Map button. Ends with a recap toast.
Future<void> playImportCelebration(
  BuildContext context,
  ImportPendingResult result, {
  Offset? from,
  bool showToast = true,
}) async {
  if (result.imported.isEmpty) {
    if (result.errors.isNotEmpty) {
      AppToast.error(context, 'Import failed',
          detail: 'Nothing was lost. Pull down to try again.');
    } else {
      AppToast.info(context, 'Already imported',
          detail: 'Those workouts were counted before.');
    }
    return;
  }

  final size = MediaQuery.of(context).size;
  final start = from ?? Offset(size.width / 2, size.height - 120);
  final hero =
      ShellAnchors.hero.center ?? Offset(size.width / 2, size.height * .32);

  if (RewardFx.enabled(context)) {
    final flights = <Future<void>>[];
    for (final (i, w) in result.imported.take(4).indexed) {
      flights.add(RewardFx.fly(
        context,
        child: AppIconImage(activityIcon(w.activityType), size: 40),
        from: start + Offset((i - (result.imported.length - 1) / 2) * 34, 0),
        to: hero,
        lift: -140,
        endScale: .4,
        duration: const Duration(milliseconds: 750),
        delay: Duration(milliseconds: i * 140),
      ));
    }
    await Future.wait(flights);
    if (!context.mounted) return;

    RewardFx.burst(context, hero, AppColors.blue, count: 16, distance: 70);
    RewardFx.ring(context, hero, AppColors.purple, maxRadius: 80);
    RewardFx.floatText(context, hero + const Offset(0, -60),
        '+${result.totalXp} XP', AppColors.orange,
        fontSize: 20, rise: 60, duration: const Duration(milliseconds: 1500));
    final gains = result.statGains.take(2).toList();
    for (final (i, g) in gains.indexed) {
      RewardFx.floatText(
        context,
        hero + Offset(i == 0 ? -72 : 72, -8),
        '${g.key} +${g.value}',
        i == 0 ? AppColors.blue : AppColors.purple,
        fontSize: 15,
        delay: Duration(milliseconds: 200 + i * 150),
      );
    }
    final avatar = ShellAnchors.avatar.center;
    if (avatar != null) {
      RewardFx.ring(context, avatar, AppColors.purple,
          maxRadius: 36, delay: const Duration(milliseconds: 250));
    }
    final orb = ShellAnchors.mapOrb.center;
    if (orb != null && result.totalAdventureDistanceKm > 0) {
      RewardFx.ring(context, orb, AppColors.green,
          maxRadius: 56, delay: const Duration(milliseconds: 600));
      RewardFx.floatText(
          context,
          orb + const Offset(0, -52),
          '+${result.totalAdventureDistanceKm.toStringAsFixed(1)} Adventure km',
          const Color(0xFF8CC0FF),
          pill: true,
          delay: const Duration(milliseconds: 600));
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!context.mounted) return;
  }

  if (showToast) showImportToast(context, result);
}

/// "+120 XP · STR +2 · 6.2 km on the map".
String importSummary(ImportPendingResult result) => <String>[
      '+${result.totalXp} XP',
      for (final g in result.statGains) '${g.key} +${g.value}',
      if (result.totalAdventureDistanceKm > 0)
        '${result.totalAdventureDistanceKm.toStringAsFixed(1)} Adventure km',
    ].join(' · ');

/// The recap toast for an import with no boss exchange to show.
void showImportToast(BuildContext context, ImportPendingResult result) {
  final n = result.imported.length;
  AppToast.success(
    context,
    'Imported $n workout${n == 1 ? '' : 's'}',
    detail: importSummary(result),
  );
}
