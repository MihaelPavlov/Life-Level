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

// Container-scoped variant for call sites where the calling widget may be
// disposed before the invalidation runs (e.g., logout — the settings sheet
// that owns the WidgetRef is unmounted once we navigate away). The root
// ProviderContainer always outlives route transitions, so invalidating
// through it is safe from post-frame callbacks after navigation.
void invalidateUserScopedProvidersFromContainer(ProviderContainer container) {
  container.invalidate(characterProfileProvider);
  container.invalidate(mapJourneyProvider);
  container.invalidate(dailyQuestsProvider);
  container.invalidate(weeklyQuestsProvider);
  container.invalidate(activityHistoryProvider);
  container.invalidate(streakProvider);
  container.invalidate(equipmentProvider);
  container.invalidate(inventoryProvider);
}
