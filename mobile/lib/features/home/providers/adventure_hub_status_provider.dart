import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../character/providers/character_provider.dart';
import '../../quests/models/quest_models.dart';
import '../../quests/providers/quest_provider.dart';
import '../../season/providers/season_provider.dart';
import '../../talents/providers/talents_provider.dart';
import '../../titles/providers/titles_provider.dart';

class AdventureHubSignals {
  final bool rewards;
  final bool talents;
  final bool season;
  final bool titles;
  final bool quests;

  const AdventureHubSignals({
    required this.rewards,
    required this.talents,
    required this.season,
    required this.titles,
    required this.quests,
  });

  static const empty = AdventureHubSignals(
    rewards: false,
    talents: false,
    season: false,
    titles: false,
    quests: false,
  );
}

final adventureHubSeenStoreProvider =
    Provider<AdventureHubSeenStore>((_) => AdventureHubSeenStore());

final adventureHubSignalsProvider =
    FutureProvider<AdventureHubSignals>((ref) async {
  final profile = ref.watch(characterProfileProvider).valueOrNull;
  final username = profile?.username;
  final talents = ref.watch(talentsProvider).valueOrNull;
  final season = ref.watch(seasonProvider).valueOrNull;
  final titles = ref.watch(titlesProvider).valueOrNull;
  final dailyQuests = ref.watch(dailyQuestsProvider).valueOrNull;
  final weeklyQuests = ref.watch(weeklyQuestsProvider).valueOrNull;
  final specialQuests = ref.watch(specialQuestsProvider).valueOrNull;

  final store = ref.watch(adventureHubSeenStoreProvider);
  final earnedTitleIds =
      titles?.earnedTitles.map((title) => title.id).toSet() ?? const <String>{};
  final completedQuestIds = completedHubQuestIds(
    dailyQuests: dailyQuests,
    weeklyQuests: weeklyQuests,
    specialQuests: specialQuests,
  );

  final titlesUpdated = username == null
      ? false
      : await store.hasNewEarnedTitles(
          username: username,
          earnedTitleIds: earnedTitleIds,
        );
  final questsUpdated = username == null
      ? false
      : await store.hasUnseenCompletedQuests(
          username: username,
          completedQuestIds: completedQuestIds,
        );

  return AdventureHubSignals(
    rewards: profile?.loginRewardAvailable ?? false,
    talents: talents?.canDraw ?? false,
    season: season?.tiers.any(
          (tier) => tier.free.isClaimable || tier.founder.isClaimable,
        ) ??
        false,
    titles: titlesUpdated,
    quests: questsUpdated,
  );
});

Set<String> completedHubQuestIds({
  List<UserQuestProgress>? dailyQuests,
  List<UserQuestProgress>? weeklyQuests,
  List<UserQuestProgress>? specialQuests,
}) {
  return {
    ...?dailyQuests
        ?.where((quest) => quest.isCompleted)
        .map((quest) => quest.id),
    ...?weeklyQuests
        ?.where((quest) => quest.isCompleted)
        .map((quest) => quest.id),
    ...?specialQuests
        ?.where((quest) => quest.isCompleted)
        .map((quest) => quest.id),
  };
}

class AdventureHubSeenStore {
  static const _prefix = 'home_adventure_hub';

  Future<bool> hasNewEarnedTitles({
    required String username,
    required Set<String> earnedTitleIds,
  }) async {
    if (earnedTitleIds.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_titlesKey(username));
    if (seen == null) return false;
    return earnedTitleIds.length > seen.length;
  }

  Future<bool> hasUnseenCompletedQuests({
    required String username,
    required Set<String> completedQuestIds,
  }) async {
    if (completedQuestIds.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_questsKey(username));
    if (seen == null) return false;
    final seenSet = seen.toSet();
    return completedQuestIds.any((id) => !seenSet.contains(id));
  }

  Future<void> markTitlesSeen({
    required String username,
    required Iterable<String> earnedTitleIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_titlesKey(username), earnedTitleIds.toList());
  }

  Future<void> markQuestsSeen({
    required String username,
    required Iterable<String> completedQuestIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_questsKey(username), completedQuestIds.toList());
  }

  String _titlesKey(String username) => '$_prefix.$username.seen_title_ids';

  String _questsKey(String username) => '$_prefix.$username.seen_quest_ids';
}
