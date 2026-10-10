import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/activity/providers/activity_provider.dart';
import '../../../features/boss/providers/boss_provider.dart';
import '../../../features/character/providers/character_provider.dart';
import '../../../features/home/providers/adventure_hub_status_provider.dart';
import '../../../features/home/providers/world_progress_provider.dart';
import '../../../features/quests/providers/quest_provider.dart';
import '../../../features/season/providers/season_provider.dart';
import '../../../features/streak/providers/streak_provider.dart';
import '../../../features/unlocks/providers/unlocks_provider.dart';

/// True while the boot loader covers Home. Level-ups, unlock ceremonies,
/// tours and boss replays wait for it, like they wait for each other.
bool bootLoaderShowing = false;

/// The four rows of the boot loader's checklist.
enum BootStep { profile, map, quests, rewards }

enum BootStepState { loading, done, failed }

extension BootStepLabel on BootStep {
  String get label => switch (this) {
        BootStep.profile => 'Hero profile',
        BootStep.map => 'Map & journey',
        BootStep.quests => 'Quests & streak',
        BootStep.rewards => 'Rewards & unlocks',
      };
}

/// Where each row stands, from the same providers Home renders.
class BootReadiness {
  final Map<BootStep, BootStepState> steps;
  const BootReadiness(this.steps);

  BootStepState operator [](BootStep s) => steps[s] ?? BootStepState.loading;

  int get doneCount =>
      steps.values.where((s) => s == BootStepState.done).length;
  bool get allDone => doneCount == BootStep.values.length;
  bool get anyFailed => steps.values.contains(BootStepState.failed);
}

/// A row is done when all its sources have data, failed when any of them
/// errored and isn't fetching again, otherwise loading.
///
/// A provider that is reloading keeps its previous error (Riverpod's
/// copyWithPrevious), e.g. the 401s from fetches made between logout and
/// the next login. Those must read as loading, or the row flashes a red "!"
/// before turning green.
BootStepState foldBootStep(List<AsyncValue<Object?>> sources) {
  if (sources.any((s) => s.hasError && !s.hasValue && !s.isLoading)) {
    return BootStepState.failed;
  }
  if (sources.every((s) => s.hasValue)) return BootStepState.done;
  return BootStepState.loading;
}

final bootReadinessProvider = Provider.autoDispose<BootReadiness>((ref) {
  return BootReadiness({
    // Level, avatar, coins and gems all come from the profile; steps from
    // the activity summary.
    BootStep.profile: foldBootStep([
      ref.watch(characterProfileProvider),
      ref.watch(activitySummaryProvider),
    ]),
    // Everything the Map button and journey card resolve from. Without these
    // the orb falls back to its "Retry" state.
    BootStep.map: foldBootStep([
      ref.watch(worldProgressProvider),
      ref.watch(currentRegionDetailProvider),
      ref.watch(bossListProvider),
    ]),
    BootStep.quests: foldBootStep([
      ref.watch(streakProvider),
      ref.watch(dailyQuestsProvider),
      ref.watch(seasonProvider),
    ]),
    // Which tabs are locked, and the Adventure Hub badges.
    BootStep.rewards: foldBootStep([
      ref.watch(unlocksProvider),
      ref.watch(adventureHubSignalsProvider),
    ]),
  });
});

/// Re-fetches every source behind [step].
void retryBootStep(WidgetRef ref, BootStep step) {
  switch (step) {
    case BootStep.profile:
      ref.invalidate(characterProfileProvider);
      ref.invalidate(activitySummaryProvider);
    case BootStep.map:
      ref.invalidate(worldProgressProvider);
      ref.invalidate(currentRegionDetailProvider);
      ref.invalidate(bossListProvider);
    case BootStep.quests:
      ref.invalidate(streakProvider);
      ref.invalidate(dailyQuestsProvider);
      ref.invalidate(seasonProvider);
    case BootStep.rewards:
      ref.read(unlocksProvider.notifier).refresh();
      ref.invalidate(adventureHubSignalsProvider);
  }
}
