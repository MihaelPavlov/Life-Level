import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quest_service.dart';
import '../models/quest_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final questServiceProvider = Provider<QuestService>((ref) => QuestService());

/// The quest endpoints lazily generate the day's quests on first hit per
/// user/day — on fresh sign-in the very first call can transiently fail before
/// the rows materialise. We do one short-delayed retry inside `build()` to
/// absorb that flake so the home card doesn't greet users with a red error
/// on cold start. Manual "Tap to retry" stays as a safety net.
const _kFirstLoadRetryDelay = Duration(milliseconds: 500);

Future<T> _withSingleRetry<T>(Future<T> Function() op) async {
  try {
    return await op();
  } catch (_) {
    await Future<void>.delayed(_kFirstLoadRetryDelay);
    return await op();
  }
}

// ── Daily quests ───────────────────────────────────────────────────────────────
class DailyQuestsNotifier extends AsyncNotifier<List<UserQuestProgress>> {
  @override
  Future<List<UserQuestProgress>> build() {
    final service = ref.watch(questServiceProvider);
    return _withSingleRetry(() => service.getDailyQuests());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(questServiceProvider).getDailyQuests(),
    );
  }
}

final dailyQuestsProvider =
    AsyncNotifierProvider<DailyQuestsNotifier, List<UserQuestProgress>>(
  DailyQuestsNotifier.new,
);

// ── Weekly quests ──────────────────────────────────────────────────────────────
class WeeklyQuestsNotifier extends AsyncNotifier<List<UserQuestProgress>> {
  @override
  Future<List<UserQuestProgress>> build() {
    final service = ref.watch(questServiceProvider);
    return _withSingleRetry(() => service.getWeeklyQuests());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(questServiceProvider).getWeeklyQuests(),
    );
  }
}

final weeklyQuestsProvider =
    AsyncNotifierProvider<WeeklyQuestsNotifier, List<UserQuestProgress>>(
  WeeklyQuestsNotifier.new,
);

// ── Special quests ─────────────────────────────────────────────────────────────
final specialQuestsProvider =
    FutureProvider.autoDispose<List<UserQuestProgress>>(
  (ref) => ref.read(questServiceProvider).getSpecialQuests(),
);
