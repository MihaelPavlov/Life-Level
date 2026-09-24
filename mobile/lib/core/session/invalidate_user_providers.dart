import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../motion/app_motion.dart';
import '../api/api_client.dart';
import '../../features/achievements/providers/achievements_provider.dart';
import '../../features/activity/providers/activity_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/boss/providers/boss_provider.dart';
import '../../features/character/providers/character_provider.dart';
import '../../features/guild/providers/guild_provider.dart';
import '../../features/home/providers/adventure_hub_status_provider.dart';
import '../../features/home/providers/world_progress_provider.dart';
import '../../features/items/providers/items_provider.dart';
import '../../features/notifications/services/notifications_service.dart';
import '../../features/quests/providers/quest_provider.dart';
import '../../features/rewards/providers/rewards_provider.dart';
import '../../features/season/providers/season_provider.dart';
import '../../features/streak/providers/streak_provider.dart';
import '../../features/talents/providers/talents_provider.dart';
import '../../features/titles/providers/titles_provider.dart';

/// Refreshes progress-backed state after mutations initiated inside a
/// Riverpod notifier, such as a Health Connect import.
void invalidateProgressProviders(Ref ref) {
  ref.invalidate(characterProfileProvider);
  ref.invalidate(worldProgressProvider);
  ref.invalidate(currentRegionDetailProvider);
  ref.invalidate(dailyQuestsProvider);
  ref.invalidate(weeklyQuestsProvider);
  ref.invalidate(rewardCenterProvider);
  ref.invalidate(activityHistoryProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(equipmentProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(bossListProvider);
  ref.invalidate(guildProvider);
  ref.invalidate(seasonProvider);
  ref.invalidate(talentsProvider);
  ref.invalidate(titlesProvider);
  ref.invalidate(achievementsProvider);
  ref.invalidate(adventureHubSignalsProvider);
}

// Call on logout, app resume, and offline→online transitions so we never
// serve the previous session's values after the auth token changes.
void invalidateUserScopedProviders(WidgetRef ref) {
  ref.invalidate(characterProfileProvider);
  ref.invalidate(worldProgressProvider);
  ref.invalidate(dailyQuestsProvider);
  ref.invalidate(weeklyQuestsProvider);
  ref.invalidate(rewardCenterProvider);
  ref.invalidate(activityHistoryProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(equipmentProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(bossListProvider);
  ref.invalidate(guildProvider);
  ref.invalidate(seasonProvider);
  ref.invalidate(talentsProvider);
  ref.invalidate(titlesProvider);
  ref.invalidate(achievementsProvider);
  ref.invalidate(adventureHubSignalsProvider);
}

// Container-scoped variant for call sites where the calling widget may be
// disposed before the invalidation runs (e.g., logout — the settings sheet
// that owns the WidgetRef is unmounted once we navigate away). The root
// ProviderContainer always outlives route transitions, so invalidating
// through it is safe from post-frame callbacks after navigation.
void invalidateUserScopedProvidersFromContainer(ProviderContainer container) {
  container.invalidate(characterProfileProvider);
  container.invalidate(worldProgressProvider);
  container.invalidate(dailyQuestsProvider);
  container.invalidate(weeklyQuestsProvider);
  container.invalidate(rewardCenterProvider);
  container.invalidate(activityHistoryProvider);
  container.invalidate(streakProvider);
  container.invalidate(equipmentProvider);
  container.invalidate(inventoryProvider);
  container.invalidate(bossListProvider);
  container.invalidate(guildProvider);
  container.invalidate(seasonProvider);
  container.invalidate(talentsProvider);
  container.invalidate(titlesProvider);
  container.invalidate(achievementsProvider);
  container.invalidate(adventureHubSignalsProvider);
}

/// Clears the JWT, routes to LoginScreen, and invalidates user-scoped providers.
/// Used by both the Profile logout tile and every ApiErrorState's Logout button.
/// Captures the root ProviderContainer before navigating so the invalidation
/// survives the caller widget being unmounted mid-transition.
Future<void> performLogout(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final navigator = Navigator.of(context, rootNavigator: true);
  final fcmToken = NotificationsService.instance.cachedToken;
  if (fcmToken != null) {
    await NotificationsService.instance.unregister(fcmToken);
  }
  await ApiClient.clearToken();
  navigator.pushAndRemoveUntil(
    AppRoute(builder: (_) => const LoginScreen(), style: AppRouteStyle.fade),
    (_) => false,
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    invalidateUserScopedProvidersFromContainer(container);
  });
}
