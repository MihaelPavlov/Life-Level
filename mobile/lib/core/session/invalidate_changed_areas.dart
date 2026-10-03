import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/achievements/providers/achievements_provider.dart';
import '../../features/activity/providers/activity_provider.dart';
import '../../features/boss/providers/boss_provider.dart';
import '../../features/character/providers/character_provider.dart';
import '../../features/guild/providers/guild_provider.dart';
import '../../features/home/providers/adventure_hub_status_provider.dart';
import '../../features/home/providers/world_progress_provider.dart';
import '../../features/items/providers/items_provider.dart';
import '../../features/leaderboard/providers/leaderboard_provider.dart';
import '../../features/notifications/providers/notification_list_provider.dart';
import '../../features/map/providers/region_chest_provider.dart';
import '../../features/modes/burn_chain/burn_chain_provider.dart';
import '../../features/modes/treasure_delve/delve_provider.dart';
import '../../features/quests/providers/quest_provider.dart';
import '../../features/rewards/providers/rewards_provider.dart';
import '../../features/season/providers/season_provider.dart';
import '../../features/streak/providers/streak_provider.dart';
import '../../features/talents/providers/talents_provider.dart';
import '../../features/titles/providers/titles_provider.dart';
import '../../features/unlocks/providers/unlocks_provider.dart';
import 'invalidate_user_providers.dart';

void invalidateChangedAreas(WidgetRef ref, Set<String> areas) {
  if (areas.contains('all')) {
    invalidateUserScopedProviders(ref);
    return;
  }
  bool has(String area) => areas.contains(area);

  if (has('character')) ref.invalidate(characterProfileProvider);
  if (has('activity')) {
    ref.invalidate(activityHistoryProvider);
    ref.invalidate(activitySummaryProvider);
    ref.invalidate(activityCalendarProvider);
  }
  if (has('achievements')) {
    ref.invalidate(achievementsProvider);
    ref.invalidate(achievementsByCategoryProvider);
    ref.invalidate(achievementRoadsProvider);
  }
  if (has('titles')) ref.invalidate(titlesProvider);
  if (has('unlocks')) ref.read(unlocksProvider.notifier).refresh();
  if (has('inventory') || has('shop')) {
    ref.read(inventoryProvider.notifier).refresh();
    ref.read(equipmentProvider.notifier).refresh();
  }
  if (has('world') || has('chests')) {
    ref.invalidate(worldProgressProvider);
    ref.invalidate(currentRegionDetailProvider);
    ref.invalidate(dungeonStateProvider);
    ref.invalidate(regionChestsProvider);
  }
  if (has('bosses')) ref.invalidate(bossListProvider);
  if (has('quests')) {
    ref.invalidate(dailyQuestsProvider);
    ref.invalidate(weeklyQuestsProvider);
  }
  if (has('rewards')) ref.invalidate(rewardCenterProvider);
  if (has('streak')) ref.invalidate(streakProvider);
  if (has('guild')) {
    ref.invalidate(guildProvider);
    ref.invalidate(guildRaidHistoryProvider);
  }
  if (has('leaderboard')) {
    ref.invalidate(leaderboardProvider);
  }
  if (has('leaderboardChest')) {
    ref.invalidate(leaderboardChestProvider);
  }
  if (has('notifications')) ref.invalidate(notificationListProvider);
  if (has('season')) ref.invalidate(seasonProvider);
  if (has('talents')) ref.invalidate(talentsProvider);
  if (has('modes')) {
    ref.invalidate(burnChainProvider);
    ref.invalidate(delveStatusProvider);
    ref.invalidate(delveRunProvider);
  }
  if (areas.any((area) => const {
        'character', 'achievements', 'titles', 'world', 'chests', 'bosses',
        'quests', 'rewards', 'streak', 'leaderboardChest', 'season', 'talents'
      }.contains(area))) {
    ref.invalidate(adventureHubSignalsProvider);
  }
}
