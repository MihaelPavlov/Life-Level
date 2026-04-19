import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/activity/providers/activity_provider.dart';
import '../../features/character/providers/character_provider.dart';
import '../../features/home/providers/map_journey_provider.dart';
import '../../features/items/providers/items_provider.dart';
import '../../features/quests/providers/quest_provider.dart';
import '../../features/streak/providers/streak_provider.dart';

// Call on logout, app resume, and offline→online transitions so we never
// serve the previous session's values after the auth token changes.
void invalidateUserScopedProviders(WidgetRef ref) {
  ref.invalidate(characterProfileProvider);
  ref.invalidate(mapJourneyProvider);
  ref.invalidate(dailyQuestsProvider);
  ref.invalidate(weeklyQuestsProvider);
  ref.invalidate(activityHistoryProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(equipmentProvider);
  ref.invalidate(inventoryProvider);
}
