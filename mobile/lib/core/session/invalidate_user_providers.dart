import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../../features/activity/providers/activity_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/boss/providers/boss_provider.dart';
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
  ref.invalidate(bossListProvider);
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
  container.invalidate(bossListProvider);
}

/// Clears the JWT, routes to LoginScreen, and invalidates user-scoped providers.
/// Used by both the Profile logout tile and every ApiErrorState's Logout button.
/// Captures the root ProviderContainer before navigating so the invalidation
/// survives the caller widget being unmounted mid-transition.
Future<void> performLogout(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final navigator = Navigator.of(context, rootNavigator: true);
  await ApiClient.clearToken();
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    invalidateUserScopedProvidersFromContainer(container);
  });
}
