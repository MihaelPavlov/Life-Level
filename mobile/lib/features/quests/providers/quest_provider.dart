import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../quest_service.dart';
import '../models/quest_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final questServiceProvider = Provider<QuestService>((ref) => QuestService());

// ── Daily quests ───────────────────────────────────────────────────────────────
class DailyQuestsNotifier extends AsyncNotifier<List<UserQuestProgress>> {
  @override
  Future<List<UserQuestProgress>> build() =>
      ref.read(questServiceProvider).getDailyQuests();

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
  Future<List<UserQuestProgress>> build() =>
      ref.read(questServiceProvider).getWeeklyQuests();

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
