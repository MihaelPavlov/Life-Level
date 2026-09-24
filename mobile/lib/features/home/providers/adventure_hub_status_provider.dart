import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../achievements/providers/achievements_provider.dart';
import '../../character/providers/character_provider.dart';
import '../../rewards/providers/rewards_provider.dart';
import '../../season/providers/season_provider.dart';
import '../../streak/providers/streak_provider.dart';
import '../../talents/providers/talents_provider.dart';
import '../../titles/providers/titles_provider.dart';

class AdventureHubSignals {
  final bool rewards;
  final bool streak;
  final bool talents;
  final bool season;
  final bool titles;
  final bool achievements;

  const AdventureHubSignals({
    required this.rewards,
    required this.streak,
    required this.talents,
    required this.season,
    required this.titles,
    required this.achievements,
  });

  static const empty = AdventureHubSignals(
    rewards: false,
    streak: false,
    talents: false,
    season: false,
    titles: false,
    achievements: false,
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
  final achievements = ref.watch(achievementsProvider).valueOrNull;
  final rewards = ref.watch(rewardCenterProvider).valueOrNull;
  final streak = ref.watch(streakProvider).valueOrNull;

  final store = ref.watch(adventureHubSeenStoreProvider);
  final earnedTitleIds =
      titles?.earnedTitles.map((title) => title.id).toSet() ?? const <String>{};
  final unlockedAchievementIds = achievements
          ?.where((achievement) => achievement.isUnlocked)
          .map((achievement) => achievement.id)
          .toSet() ??
      const <String>{};

  final titlesUpdated = username == null
      ? false
      : await store.hasNewEarnedTitles(
          username: username,
          earnedTitleIds: earnedTitleIds,
        );
  final achievementsUpdated = username == null
      ? false
      : await store.hasUnseenAchievements(
          username: username,
          unlockedAchievementIds: unlockedAchievementIds,
        );

  return AdventureHubSignals(
    rewards: rewards?.hasClaimableReward ?? false,
    streak: streak?.canClaimDailyReward ?? false,
    talents: talents?.canDraw ?? false,
    season: season?.hasClaimableReward ?? false,
    titles: titlesUpdated,
    achievements: achievementsUpdated,
  );
});

class AdventureHubSeenStore {
  static const _prefix = 'home_adventure_hub';

  Future<bool> hasNewEarnedTitles({
    required String username,
    required Set<String> earnedTitleIds,
  }) async {
    if (earnedTitleIds.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_titlesKey(username));
    if (seen == null) return true;
    final seenSet = seen.toSet();
    return earnedTitleIds.any((id) => !seenSet.contains(id));
  }

  Future<void> markTitlesSeen({
    required String username,
    required Iterable<String> earnedTitleIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_titlesKey(username), earnedTitleIds.toList());
  }

  Future<bool> hasUnseenAchievements({
    required String username,
    required Set<String> unlockedAchievementIds,
  }) async {
    if (unlockedAchievementIds.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_achievementsKey(username));
    if (seen == null) return true;
    final seenSet = seen.toSet();
    return unlockedAchievementIds.any((id) => !seenSet.contains(id));
  }

  Future<void> markAchievementsSeen({
    required String username,
    required Iterable<String> unlockedAchievementIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _achievementsKey(username),
      unlockedAchievementIds.toList(),
    );
  }

  String _titlesKey(String username) => '$_prefix.$username.seen_title_ids';

  String _achievementsKey(String username) =>
      '$_prefix.$username.seen_achievement_ids';
}
