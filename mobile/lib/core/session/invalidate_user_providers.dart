import 'dart:async';

import 'package:flutter/material.dart';
import '../../features/boss/replay/boss_seen_store.dart';
import '../../features/auth/services/google_sign_in_coordinator.dart';
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
import '../../features/leaderboard/providers/leaderboard_provider.dart';
import '../../features/items/providers/items_provider.dart';
import '../../features/notifications/services/notifications_service.dart';
import '../../features/notifications/providers/notification_list_provider.dart';
import '../../features/quests/providers/quest_provider.dart';
import '../../features/rewards/providers/rewards_provider.dart';
import '../../features/season/providers/season_provider.dart';
import '../../features/streak/providers/streak_provider.dart';
import '../../features/talents/providers/talents_provider.dart';
import '../../features/titles/providers/titles_provider.dart';
import '../../features/modes/burn_chain/burn_chain_provider.dart';
import '../../features/modes/treasure_delve/delve_provider.dart';
import '../../features/map/providers/region_chest_provider.dart';
import '../../features/unlocks/providers/unlocks_provider.dart';

/// Refreshes progress-backed state after mutations initiated inside a
/// Riverpod notifier, such as a Health Connect import.
void invalidateProgressProviders(Ref ref) {
  ref.invalidate(characterProfileProvider);
  ref.invalidate(worldProgressProvider);
  ref.invalidate(currentRegionDetailProvider);
  ref.invalidate(dungeonStateProvider);
  ref.invalidate(dailyQuestsProvider);
  ref.invalidate(weeklyQuestsProvider);
  ref.invalidate(rewardCenterProvider);
  ref.invalidate(activityHistoryProvider);
  ref.invalidate(activitySummaryProvider);
  ref.invalidate(activityCalendarProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(equipmentProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(bossListProvider);
  ref.invalidate(leaderboardChestProvider);
  ref.invalidate(leaderboardProvider);
  ref.invalidate(notificationListProvider);
  ref.invalidate(regionChestsProvider);
  ref.invalidate(guildProvider);
  ref.invalidate(seasonProvider);
  ref.invalidate(talentsProvider);
  ref.invalidate(titlesProvider);
  ref.invalidate(achievementsProvider);
  ref.invalidate(adventureHubSignalsProvider);
  ref.invalidate(burnChainProvider);
  ref.invalidate(delveStatusProvider);
  ref.invalidate(delveRunProvider);
  // Refreshed rather than invalidated so locked slots don't flash open.
  ref.read(unlocksProvider.notifier).refresh();
}

// Call on logout, app resume, and offline→online transitions so we never
// serve the previous session's values after the auth token changes.
void invalidateUserScopedProviders(WidgetRef ref) {
  ref.invalidate(characterProfileProvider);
  ref.invalidate(worldProgressProvider);
  ref.invalidate(currentRegionDetailProvider);
  ref.invalidate(dungeonStateProvider);
  ref.invalidate(dailyQuestsProvider);
  ref.invalidate(weeklyQuestsProvider);
  ref.invalidate(rewardCenterProvider);
  ref.invalidate(activityHistoryProvider);
  ref.invalidate(activitySummaryProvider);
  ref.invalidate(activityCalendarProvider);
  ref.invalidate(streakProvider);
  ref.invalidate(equipmentProvider);
  ref.invalidate(inventoryProvider);
  ref.invalidate(bossListProvider);
  ref.invalidate(leaderboardChestProvider);
  ref.invalidate(leaderboardProvider);
  ref.invalidate(notificationListProvider);
  ref.invalidate(regionChestsProvider);
  ref.invalidate(guildProvider);
  ref.invalidate(seasonProvider);
  ref.invalidate(talentsProvider);
  ref.invalidate(titlesProvider);
  ref.invalidate(achievementsProvider);
  ref.invalidate(adventureHubSignalsProvider);
  ref.invalidate(adventureHubSeenMigrationProvider);
  ref.invalidate(burnChainProvider);
  ref.invalidate(delveStatusProvider);
  ref.invalidate(delveRunProvider);
  ref.read(unlocksProvider.notifier).refresh();
}

// Container-scoped variant for call sites where the calling widget may be
// disposed before the invalidation runs (e.g., logout — the settings sheet
// that owns the WidgetRef is unmounted once we navigate away). The root
// ProviderContainer always outlives route transitions, so invalidating
// through it is safe from post-frame callbacks after navigation.
void invalidateUserScopedProvidersFromContainer(ProviderContainer container) {
  container.invalidate(characterProfileProvider);
  container.invalidate(worldProgressProvider);
  container.invalidate(currentRegionDetailProvider);
  container.invalidate(dungeonStateProvider);
  container.invalidate(dailyQuestsProvider);
  container.invalidate(weeklyQuestsProvider);
  container.invalidate(rewardCenterProvider);
  container.invalidate(activityHistoryProvider);
  container.invalidate(activitySummaryProvider);
  container.invalidate(activityCalendarProvider);
  container.invalidate(streakProvider);
  container.invalidate(equipmentProvider);
  container.invalidate(inventoryProvider);
  container.invalidate(bossListProvider);
  container.invalidate(leaderboardChestProvider);
  container.invalidate(leaderboardProvider);
  container.invalidate(notificationListProvider);
  container.invalidate(regionChestsProvider);
  container.invalidate(guildProvider);
  container.invalidate(seasonProvider);
  container.invalidate(talentsProvider);
  container.invalidate(titlesProvider);
  container.invalidate(achievementsProvider);
  container.invalidate(unlocksProvider);
  container.invalidate(adventureHubSignalsProvider);
  container.invalidate(adventureHubSeenMigrationProvider);
  container.invalidate(burnChainProvider);
  container.invalidate(delveStatusProvider);
  container.invalidate(delveRunProvider);
}

bool _logoutInFlight = false;

/// Logs out instantly (design: Logout Flow Redesign canvas, "L1 · Instant
/// out"). Used by both the Profile logout tile and every ApiErrorState's
/// Logout button.
///
/// Only the local token is cleared before Login opens; the push-token
/// unregister, Google sign-out and boss-seen reset finish in the background
/// with a timeout and never block or surface errors. User-scoped providers
/// are invalidated once the old screens have gone, so nothing re-fetches
/// without a token on the way out.
Future<void> performLogout(BuildContext context) async {
  if (_logoutInFlight) return;
  _logoutInFlight = true;
  final container = ProviderScope.containerOf(context, listen: false);
  final navigator = Navigator.of(context, rootNavigator: true);
  final fcmToken = NotificationsService.instance.cachedToken;
  // Grab the JWT first: the unregister call still has to be signed.
  final jwt = await ApiClient.getToken();
  try {
    await ApiClient.clearToken();
  } catch (_) {
    // Local storage trouble must not keep the player logged in on screen.
  }

  final route = AppRoute<void>(
    builder: (_) => const LoginScreen(signedOut: true),
    style: AppRouteStyle.fade,
  );
  navigator.pushAndRemoveUntil(route, (_) => false);

  var invalidated = false;
  void invalidateOnce() {
    if (invalidated) return;
    invalidated = true;
    // One more frame so the removed routes have been disposed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      invalidateUserScopedProvidersFromContainer(container);
      _logoutInFlight = false;
    });
  }

  final animation = route.animation;
  if (animation == null || animation.isCompleted) {
    invalidateOnce();
  } else {
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) invalidateOnce();
    });
    // Safety net if the transition is interrupted.
    Future<void>.delayed(const Duration(seconds: 2), invalidateOnce);
  }

  unawaited(_finishLogoutInBackground(fcmToken: fcmToken, jwt: jwt));
}

Future<void> _finishLogoutInBackground(
    {required String? fcmToken, required String? jwt}) async {
  const limit = Duration(seconds: 5);
  Future<void> capped(Future<void> work) =>
      work.timeout(limit, onTimeout: () {}).catchError((Object _) {});
  await Future.wait([
    if (fcmToken != null && jwt != null)
      capped(NotificationsService.instance.unregister(fcmToken, authToken: jwt)),
    capped(GoogleSignInCoordinator.instance.signOut()),
    capped(BossSeenStore.instance.clear()),
  ]);
}
