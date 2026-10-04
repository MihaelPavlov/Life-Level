import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_colors.dart';
import '../motion/app_motion.dart';
import '../../features/character/providers/character_provider.dart';
import '../../features/character/services/character_service.dart';
import '../session/invalidate_user_providers.dart';
import '../session/invalidate_changed_areas.dart';
import '../services/state_change_notifier.dart';
import '../services/pending_welcome.dart';
import '../services/oauth_code_guard.dart';
import '../services/boss_defeated_notifier.dart';
import '../services/boss_overlay_notifier.dart';
import '../services/deep_link_notifier.dart';
import '../services/dungeon_floor_cleared_notifier.dart';
import '../services/guild_raid_victory_notifier.dart';
import '../services/level_up_notifier.dart';
import '../services/item_obtained_notifier.dart';
import '../services/inventory_full_notifier.dart';
import '../services/notification_banner_notifier.dart';
import '../widgets/boss_defeated_overlay.dart';
import '../widgets/dungeon_floor_cleared_overlay.dart';
import '../widgets/guild_raid_expired_overlay.dart';
import '../widgets/guild_raid_victory_overlay.dart';
import '../widgets/level_up_overlay.dart';
import '../widgets/item_obtained_overlay.dart';
import '../widgets/inventory_full_overlay.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/providers/adventure_hub_status_provider.dart';
import '../../features/achievements/achievements_screen.dart';
import '../../features/home/providers/world_progress_provider.dart';
import '../../features/rewards/rewards_screen.dart';
import '../../features/gear/gear_screen.dart';
import '../../features/map/screens/world_hub_screen.dart';
import '../services/nav_tab_notifier.dart';
import '../services/shell_overlay_notifier.dart';
import '../services/world_map_notifier.dart';
import '../services/world_zone_refresh_notifier.dart';
import '../../features/integrations/providers/integrations_provider.dart';
import '../../features/notifications/services/notifications_service.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/modes/modes_screen.dart';
import '../../features/modes/burn_chain/burn_chain_provider.dart';
import '../../features/modes/treasure_delve/delve_provider.dart';
import '../../features/titles/titles_ranks_screen.dart';
import '../../features/season/season_track_screen.dart';
import '../../features/talents/talents_screen.dart';
import '../../features/boss/screens/boss_screen.dart';
import '../../features/guild/providers/guild_provider.dart';
import '../../features/guild/models/guild_models.dart';
import '../../features/guild/screens/guild_screen.dart';
import '../../features/guild/services/guild_realtime_service.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/boss/providers/boss_provider.dart';
import '../../features/boss/replay/boss_replay.dart';
import '../../features/boss/replay/boss_seen_store.dart';
import '../../features/boss/replay/home_boss_replay.dart';
import '../../features/items/models/item_models.dart';
import '../../features/items/providers/items_provider.dart';
import '../widgets/app_toast.dart';
import 'shell_constants.dart';
import 'widgets/journey_popover.dart';
import 'widgets/map_orb_button.dart';
import 'widgets/shell_tab_bar.dart';
import '../../features/activity/log_activity_screen.dart';
import '../../features/map/screens/region_chests_screen.dart';
import '../../features/sync/providers/pending_workouts_provider.dart';
import '../../features/sync/pull_import_flow.dart';
import '../../features/streak/widgets/streak_detail_sheet.dart';
import '../../features/unlocks/models/unlock_catalog.dart';
import '../../features/unlocks/providers/unlocks_provider.dart';
import '../../features/unlocks/tour/feature_tour.dart';
import '../../features/unlocks/tour/unlock_tour_runner.dart';
import '../../features/unlocks/unlock_coordinator.dart';
import '../../features/unlocks/widgets/unlock_badges.dart';

// ── shell ─────────────────────────────────────────────────────────────────────
class MainShell extends ConsumerStatefulWidget {
  final List<String>? initialRingIds;
  final List<String>? initialNavIds;
  const MainShell({super.key, this.initialRingIds, this.initialNavIds});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _tabIndex = 0;
  bool _journeyOpen = false;
  bool _worldOpen = false;
  ValueChanged<ZonePick>? _pendingOnZoneSelected;
  bool _titlesOpen = false;
  bool _bossOpen = false;
  bool _guildOpen = false;
  bool _questsOpen = false;
  bool _seasonOpen = false;
  bool _talentsOpen = false;
  bool _achievementsOpen = false;

  /// Carried alongside `_bossOpen` to deep-link the boss overlay straight
  /// into a specific boss's battle view (set when the home portal "Fight →"
  /// CTA fires, cleared when the overlay closes).
  String? _pendingBossId;
  bool _worldAutoOpenActive = false;
  String? _worldTargetRegionId;
  String? _worldTargetZoneId;
  bool _checkingPendingGuildVictories = false;
  bool _checkingPendingGuildExpiries = false;
  final Set<String> _guildVictoryInFlight = <String>{};
  final Set<String> _guildVictoryShownThisSession = <String>{};
  final Set<String> _guildExpiryInFlight = <String>{};
  final Set<String> _guildExpiryShownThisSession = <String>{};
  String? _lastRealtimeGuildId;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  bool _wasOffline = false;
  StreamSubscription<Uri>? _deepLinkSub;
  bool _oauthCallbackHandled = false;

  final _guildRealtime = GuildRealtimeService();

  /// Tabs in the IndexedStack. Map is not a tab: the Map button opens the
  /// journey card.
  static const _navIds = ['home', 'gear', 'profile', 'modes'];
  late final StreamSubscription<LevelUpEvent> _levelUpSub;
  late final StreamSubscription<Set<String>> _stateChangeSub;
  Timer? _stateChangeDebounce;
  final Set<String> _queuedAreas = {};
  late final StreamSubscription<ItemDto> _itemObtainedSub;
  late final StreamSubscription<String> _navTabSub;
  late final StreamSubscription<String> _shellOverlaySub;
  late final StreamSubscription<String> _tourReplaySub;
  late final StreamSubscription<WorldMapOpenRequest> _worldMapSub;
  late final StreamSubscription<void> _worldRefreshSub;
  late final StreamSubscription<BlockedItemInfo> _inventoryFullSub;
  late final StreamSubscription<DungeonFloorClearedEvent> _dungeonFloorSub;
  late final StreamSubscription<GuildRaidVictoryInfo> _guildRaidVictorySub;
  late final StreamSubscription<BossOpenIntent> _bossOverlaySub;
  late final StreamSubscription<BossDefeatedInfo> _bossDefeatedSub;
  late final StreamSubscription<Uri> _deepLinkNotifierSub;
  late final StreamSubscription<NotificationBannerPayload>
      _notificationBannerSub;
  final _characterService = CharacterService();
  final Set<String> _shownLevelUpReceipts = {};
  bool _checkingLevelUps = false;
  StreamSubscription<void>? _bossReplaySub;
  bool _bossReplayFetching = false;
  bool _bossReplayWaiting = false;

  final _mapNavKey = GlobalKey();

  void _openRewardsDialog() {
    if (!mounted) return;
    showRewardsSheet(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Connectivity().checkConnectivity().then((results) {
      _wasOffline = results.every((r) => r == ConnectivityResult.none);
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (_wasOffline && isOnline) {
        _invalidateAllProviders();
        unawaited(_startGuildRealtime());
        _checkPendingGuildRaidVictories();
        _checkPendingGuildRaidExpiries();
      }
      _wasOffline = !isOnline;
    });
    _levelUpSub = LevelUpNotifier.stream.listen((_) => _checkPendingLevelUps());
    _stateChangeSub = StateChangeNotifier.stream.listen((areas) {
      _queuedAreas.addAll(areas);
      _stateChangeDebounce?.cancel();
      _stateChangeDebounce = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        final changed = {..._queuedAreas};
        _queuedAreas.clear();
        invalidateChangedAreas(ref, changed);
        if (changed.contains('levelUps')) _checkPendingLevelUps();
        if (changed.contains('pendingWorkouts')) {
          ref.read(pendingWorkoutsProvider.notifier).checkQuietly();
        }
        if (changed.contains('bosses')) unawaited(_maybePlayBossReplay());
        if (changed.contains('guild')) {
          _checkPendingGuildRaidVictories();
          _checkPendingGuildRaidExpiries();
        }
      });
    });
    _bossReplaySub =
        bossReplayRequests.listen((r) => unawaited(_maybePlayBossReplay(r)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybePlayBossReplay());
      _checkPendingLevelUps();
    });
    _itemObtainedSub = ItemObtainedNotifier.stream.listen((item) {
      if (!mounted) return;
      showItemObtainedOverlay(context, item);
      ref.read(unlocksProvider.notifier).refresh();
    });
    _navTabSub = NavTabNotifier.stream.listen((tabId) {
      if (!mounted) return;
      _closeJourney();
      final navIndex = _navIds.indexOf(tabId);
      // 'world' is rendered as an overlay above the IndexedStack — switching
      // to it without opening the overlay would leave the user staring at
      // SizedBox.shrink(). Open the overlay alongside the tab switch so
      // programmatic NavTabNotifier.switchTo('world') matches the behaviour
      // of tapping the bottom-nav 'world' icon.
      if (tabId == 'world') {
        WorldZoneRefreshNotifier.notify();
        setState(() {
          if (navIndex != -1) _tabIndex = navIndex;
          _pendingOnZoneSelected = null;
          _worldOpen = true;
          _worldAutoOpenActive = false;
          _worldTargetRegionId = null;
          _worldTargetZoneId = null;
          _titlesOpen = false;
          _bossOpen = false;
          _guildOpen = false;
          _seasonOpen = false;
          _talentsOpen = false;
        });
        return;
      }
      if (navIndex != -1) {
        setState(() {
          _tabIndex = navIndex;
          _guildOpen = false;
          _questsOpen = false;
          _seasonOpen = false;
          _talentsOpen = false;
        });
      }
    });
    _shellOverlaySub = ShellOverlayNotifier.stream.listen((id) {
      if (!mounted) return;
      _onRingItemTap(id);
    });
    _tourReplaySub = UnlockReplay.stream.listen((key) {
      if (mounted) unawaited(_openUnlockedFeature(key, replay: true));
    });
    _worldMapSub = WorldMapNotifier.stream.listen((event) {
      if (!mounted) return;
      WorldZoneRefreshNotifier.notify();
      final navIndex = _navIds.indexOf('world');
      setState(() {
        // An action on the journey card (Travel here, View on map…) hands
        // over to the map, so the card closes.
        _journeyOpen = false;
        if (navIndex != -1) _tabIndex = navIndex;
        _pendingOnZoneSelected = event.onZoneSelected;
        _worldOpen = true;
        _worldAutoOpenActive = event.autoOpenActiveRegion;
        _worldTargetRegionId = event.regionId;
        _worldTargetZoneId = event.zoneId;
        _titlesOpen = false;
        _bossOpen = false;
        _guildOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
      });
    });
    // Keep the always-visible Map orb in sync with every world mutation.
    // Individual map/home screens also consume this signal for their own
    // local reloads, but the orb must not depend on any of those screens
    // being mounted when travel reaches a new zone.
    _worldRefreshSub = WorldZoneRefreshNotifier.stream.listen((_) {
      if (!mounted) return;
      ref.invalidate(worldProgressProvider);
      ref.invalidate(currentRegionDetailProvider);
      ref.invalidate(dungeonStateProvider);
      ref.invalidate(bossListProvider);
    });
    _inventoryFullSub = InventoryFullNotifier.stream.listen((item) {
      if (mounted) {
        final level =
            ref.read(characterProfileProvider).valueOrNull?.level ?? 1;
        showInventoryFullOverlay(context, item, level);
      }
    });
    _dungeonFloorSub = DungeonFloorClearedNotifier.stream.listen((event) {
      if (!mounted) return;
      showDungeonFloorClearedOverlay(context, event);
    });
    _guildRaidVictorySub = GuildRaidVictoryNotifier.stream.listen((info) {
      if (!mounted) return;
      _showAndAcknowledgeGuildRaidVictory(info);
    });
    _bossDefeatedSub = BossDefeatedNotifier.stream.listen((info) {
      if (!mounted) return;
      ref.invalidate(bossListProvider);
      ref.invalidate(worldProgressProvider);
      WorldZoneRefreshNotifier.notify();
      showBossDefeatedOverlay(context, info);
    });
    _bossOverlaySub = BossOverlayNotifier.stream.listen((intent) {
      if (!mounted) return;
      // Fresh-fetch the boss list so the just-spawned world-zone boss
      // appears, then flip the existing shell overlay — same surface the
      // ring-menu boss item opens. `intent.bossId` (when present) tells
      // BossScreen to auto-open the battle view for that boss.
      ref.invalidate(bossListProvider);
      setState(() {
        _journeyOpen = false;
        _worldOpen = false;
        _titlesOpen = false;
        _bossOpen = true;
        _guildOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
        _pendingBossId = intent.bossId;
      });
    });

    // OAuth deep-link handling — runs for both cold starts and warm resumes.
    // Cold start: getInitialLink() delivers the URI that launched the app.
    // Warm start: uriLinkStream delivers it while the app is already running.
    _deepLinkSub = AppLinks().uriLinkStream.listen(_handleDeepLink);
    AppLinks().getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // Notification-tap deep links route through the same handler so logic
    // stays in one place (see DeepLinkNotifier + NotificationsService).
    _deepLinkNotifierSub = DeepLinkNotifier.stream.listen(_handleDeepLink);

    // Foreground push notification banners shown as AppToast overlays.
    _notificationBannerSub =
        NotificationBannerNotifier.stream.listen((payload) {
      if (!mounted) return;
      AppToast.info(
        context,
        payload.body.isEmpty
            ? payload.title
            : '${payload.title}\n${payload.body}',
        icon: Icons.notifications_active_rounded,
        duration: const Duration(seconds: 4),
      );
    });

    // Greeting handed over by onboarding (first landing on Home).
    final welcome = PendingWelcome.take();
    if (welcome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppToast.success(context, welcome,
            duration: const Duration(seconds: 4));
      });
    }

    // FCM push notifications: request permission, fetch+register token,
    // attach listeners. Idempotent — safe to call on every shell mount.
    NotificationsService.instance.initialize(ref);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startGuildRealtime());
      _checkPendingGuildRaidVictories();
      _checkPendingGuildRaidExpiries();
      unawaited(_migrateSeenState());
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'lifelevel') return;
    if (!mounted) return;

    // ── OAuth callback (Strava) — keep existing behaviour intact ──────────
    if (uri.host == 'oauth') {
      final code = uri.queryParameters['code'];
      if (code == null) return;
      if (uri.pathSegments.contains('strava')) {
        if (_oauthCallbackHandled) return;
        if (!OAuthCodeGuard.claim(code)) return;
        _oauthCallbackHandled = true;
        _handleStravaCallback(code);
      }
      return;
    }

    // ── Notification deep links ────────────────────────────────────────────
    switch (uri.host) {
      case 'home':
        // "New workout ready" push: refresh the queue so the pill shows.
        ref.read(pendingWorkoutsProvider.notifier).checkQuietly();
        final navIndex = _navIds.indexOf('home');
        if (navIndex != -1) {
          setState(() {
            _tabIndex = navIndex;
            _worldOpen = false;
            _titlesOpen = false;
            _bossOpen = false;
            _guildOpen = false;
            _questsOpen = false;
            _seasonOpen = false;
            _talentsOpen = false;
          });
        }

      case 'quests':
      case 'rewards':
        _openRewardsDialog();

      case 'gear':
        final navIndex = _navIds.indexOf('gear');
        if (navIndex != -1) {
          setState(() {
            _tabIndex = navIndex;
            _worldOpen = false;
            _titlesOpen = false;
            _bossOpen = false;
            _guildOpen = false;
            _questsOpen = false;
            _seasonOpen = false;
            _talentsOpen = false;
          });
        }

      case 'boss':
        setState(() {
          _journeyOpen = false;
          _worldOpen = false;
          _titlesOpen = false;
          _bossOpen = true;
          _guildOpen = false;
          _seasonOpen = false;
          _talentsOpen = false;
        });

      case 'guild':
        final navIndex = _navIds.indexOf('guild');
        setState(() {
          _journeyOpen = false;
          _worldOpen = false;
          _titlesOpen = false;
          _bossOpen = false;
          _guildOpen = navIndex == -1;
          _questsOpen = false;
          _seasonOpen = false;
          _talentsOpen = false;
          if (navIndex != -1) _tabIndex = navIndex;
        });

      case 'season':
        setState(() {
          _journeyOpen = false;
          _worldOpen = false;
          _titlesOpen = false;
          _bossOpen = false;
          _guildOpen = false;
          _questsOpen = false;
          _seasonOpen = true;
          _talentsOpen = false;
        });

      case 'talents':
        setState(() {
          _journeyOpen = false;
          _worldOpen = false;
          _titlesOpen = false;
          _bossOpen = false;
          _guildOpen = false;
          _questsOpen = false;
          _seasonOpen = false;
          _talentsOpen = true;
        });

      case 'map':
      case 'world':
        WorldZoneRefreshNotifier.notify();
        final navIndex = _navIds.indexOf('world');
        setState(() {
          if (navIndex != -1) _tabIndex = navIndex;
          _pendingOnZoneSelected = null;
          _worldOpen = true;
          _titlesOpen = false;
          _bossOpen = false;
          _guildOpen = false;
          _questsOpen = false;
          _seasonOpen = false;
          _talentsOpen = false;
        });

      case 'profile':
        final navIndex = _navIds.indexOf('profile');
        if (navIndex != -1) {
          setState(() {
            _tabIndex = navIndex;
            _worldOpen = false;
            _titlesOpen = false;
            _bossOpen = false;
            _guildOpen = false;
            _questsOpen = false;
            _seasonOpen = false;
            _talentsOpen = false;
          });
        }
    }
  }

  void _handleStravaCallback(String code) {
    if (!mounted) return;
    AppToast.info(context, 'Connecting to Strava...', icon: Icons.sync_rounded);
    ref
        .read(integrationSyncProvider.notifier)
        .connectStrava(code)
        .then((error) async {
      _oauthCallbackHandled = false;
      await ref.read(integrationSyncProvider.notifier).refresh();
      if (!mounted) return;
      final connected = ref.read(integrationSyncProvider).isStravaConnected;
      final message = connected
          ? 'Strava connected!'
          : 'Failed: ${error ?? 'unknown error'}';
      if (connected) {
        AppToast.success(context, message,
            duration: const Duration(seconds: 8));
      } else {
        AppToast.error(context, message, duration: const Duration(seconds: 8));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _levelUpSub.cancel();
    _stateChangeSub.cancel();
    _stateChangeDebounce?.cancel();
    _bossReplaySub?.cancel();
    _itemObtainedSub.cancel();
    _dungeonFloorSub.cancel();
    _guildRaidVictorySub.cancel();
    _bossOverlaySub.cancel();
    _bossDefeatedSub.cancel();
    _navTabSub.cancel();
    _shellOverlaySub.cancel();
    _tourReplaySub.cancel();
    _worldMapSub.cancel();
    _worldRefreshSub.cancel();
    _inventoryFullSub.cancel();
    _connectivitySub.cancel();
    _deepLinkSub?.cancel();
    _deepLinkNotifierSub.cancel();
    _notificationBannerSub.cancel();
    unawaited(_guildRealtime.stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerForegroundHealthSync();
      _invalidateAllProviders();
      unawaited(_startGuildRealtime());
      _checkPendingGuildRaidVictories();
      _checkPendingGuildRaidExpiries();
      unawaited(_maybePlayBossReplay());
      _checkPendingLevelUps();
    }
  }

  // ── boss replay ─────────────────────────────────────────────────────────
  /// Home is on screen with nothing covering it.
  bool _canPlayBossReplay() =>
      mounted &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      !_checkingLevelUps &&
      !_journeyOpen &&
      !unlockCeremonyShowing &&
      !FeatureTour.isRunning &&
      _activeShellOverlay() == null &&
      _navIds[_tabIndex.clamp(0, _navIds.length - 1)] == 'home';

  /// Looks for boss exchanges the player hasn't seen and plays them on the
  /// Map button once Home is free. Level-ups and unlock ceremonies wait.
  Future<void> _maybePlayBossReplay([BossReplayRequest? request]) async {
    if (!mounted ||
        _bossReplayFetching ||
        _bossReplayWaiting ||
        homeBossReplayRunning) {
      // Already on it; whatever this request carried is shown the usual way.
      request?.orElse?.call();
      return;
    }
    _bossReplayFetching = true;
    BossReplay? replay;
    try {
      replay = await BossReplayFinder.find(ref.read(bossPageServiceProvider));
    } catch (_) {
      // Offline: try again on the next request.
    } finally {
      _bossReplayFetching = false;
    }
    if (replay == null || !mounted) {
      request?.orElse?.call();
      return;
    }

    _bossReplayWaiting = true;
    try {
      while (mounted && !_canPlayBossReplay()) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    } finally {
      _bossReplayWaiting = false;
    }
    if (!mounted) return;
    // Watched meanwhile (Bosses page, journey card): nothing left to play.
    final seen = BossSeenStore.instance[replay.boss.id];
    if (seen != null && !seen.turnAt.isBefore(replay.last.at)) {
      // Bring the rings up to the live values.
      unawaited(BossReplayFinder.find(ref.read(bossPageServiceProvider),
              onlyBossId: replay.boss.id)
          .catchError((_) => null));
      request?.orElse?.call();
      return;
    }
    await playHomeBossReplay(context, replay, summary: request?.summary);
    if (!mounted) return;
    ref.invalidate(bossListProvider);
    setState(() {});
    // Another boss may have news too; then the queued celebrations.
    unawaited(_maybePlayBossReplay());
    _checkPendingLevelUps();
  }

  Future<void> _checkPendingLevelUps() async {
    if (!mounted || _checkingLevelUps) return;
    final onHome = _navIds[_tabIndex.clamp(0, _navIds.length - 1)] == 'home';
    if (_bossReplayFetching ||
        homeBossReplayRunning ||
        (_bossReplayWaiting && onHome) ||
        unlockCeremonyShowing ||
        unlockMomentRunning ||
        FeatureTour.isRunning) {
      // The boss exchange plays first; level-ups follow it. An unlock
      // ceremony or tour already on screen finishes before a level-up.
      Future<void>.delayed(
          const Duration(milliseconds: 900), _checkPendingLevelUps);
      return;
    }
    _checkingLevelUps = true;
    try {
      final pending = await _characterService.getPendingLevelUps();
      for (final receipt in pending) {
        if (!mounted || _shownLevelUpReceipts.contains(receipt.id)) continue;
        _shownLevelUpReceipts.add(receipt.id);
        await showLevelUpScreen(
          context,
          receipt.newLevel,
          receipt: receipt,
        );
        try {
          await _characterService.acknowledgeLevelUp(receipt.id);
        } catch (_) {
          // Do not trap the player offline. The server receipt remains pending
          // and will be retried in a later app session.
        }
      }
      if (pending.isNotEmpty) {
        ref.invalidate(inventoryProvider);
        ref.invalidate(characterProfileProvider);
        ref.read(unlocksProvider.notifier).refresh();
      }
    } catch (_) {
      // Pending celebrations are durable on the server and retry on resume.
    } finally {
      _checkingLevelUps = false;
    }
  }

  /// On resume, queue anything new from the phone's health store and refresh
  /// the pending pill. Nothing is imported until the player pulls Home.
  Future<void> _triggerForegroundHealthSync() async {
    await ref.read(pendingWorkoutsProvider.notifier).checkQuietly();
  }

  Future<void> _migrateSeenState() async {
    try {
      await ref.read(adventureHubSeenMigrationProvider.future);
    } catch (_) {
      // Retry next launch if the server or profile is unavailable.
    }
  }

  void _invalidateAllProviders() {
    if (!mounted) return;
    invalidateUserScopedProviders(ref);
  }

  Future<void> _startGuildRealtime() async {
    await _guildRealtime.start(
      onReconnected: () {
        if (!mounted) return;
        _invalidateAllProviders();
        ref.read(pendingWorkoutsProvider.notifier).checkQuietly();
        _checkPendingLevelUps();
        _checkPendingGuildRaidVictories();
        _checkPendingGuildRaidExpiries();
        unawaited(_maybePlayBossReplay());
      },
      onStarted: (info) {
        if (!mounted) return;
        ref.invalidate(guildProvider);
        ref.invalidate(guildRaidHistoryProvider);
        AppToast.info(
          context,
          '${info.bossName} guild raid started',
          icon: Icons.shield_rounded,
        );
      },
      onHpUpdated: (info) {
        if (!mounted) return;
        ref.invalidate(guildProvider);
        ref.invalidate(guildRaidHistoryProvider);
      },
      onDefeated: (info) {
        if (!mounted) return;
        ref.invalidate(guildProvider);
        ref.invalidate(guildRaidHistoryProvider);
        _checkPendingGuildRaidVictories();
      },
      onExpired: (info) {
        if (!mounted) return;
        ref.invalidate(guildProvider);
        ref.invalidate(guildRaidHistoryProvider);
        unawaited(_showAndAcknowledgeGuildRaidExpiry(info));
      },
    );
  }

  Future<void> _checkPendingGuildRaidVictories() async {
    if (!mounted || _checkingPendingGuildVictories) return;
    _checkingPendingGuildVictories = true;
    try {
      final pending =
          await ref.read(guildServiceProvider).pendingRaidVictories();
      for (final info in pending) {
        if (!mounted) return;
        await _showAndAcknowledgeGuildRaidVictory(info);
      }
    } catch (_) {
      // Non-blocking: missing guild, auth refresh, or network issues should not
      // interrupt app startup.
    } finally {
      _checkingPendingGuildVictories = false;
    }
  }

  Future<void> _showAndAcknowledgeGuildRaidVictory(
    GuildRaidVictoryInfo info,
  ) async {
    if (!mounted) return;
    final key = info.guildRaidId.isNotEmpty
        ? info.guildRaidId
        : '${info.guildId}:${info.bossName}:${info.rewardXp}';
    if (_guildVictoryInFlight.contains(key) ||
        _guildVictoryShownThisSession.contains(key)) {
      return;
    }

    _guildVictoryInFlight.add(key);
    ref.invalidate(guildProvider);
    try {
      await showGuildRaidVictoryOverlay(context, info);
      _guildVictoryShownThisSession.add(key);
      if (!mounted || info.guildRaidId.isEmpty) return;
      try {
        await ref
            .read(guildServiceProvider)
            .acknowledgeRaidVictory(info.guildRaidId);
      } catch (_) {
        // If acknowledgement fails, the backend can offer the modal again on a
        // later sign-in. The session guard still prevents duplicate popups now.
      }
    } finally {
      _guildVictoryInFlight.remove(key);
    }
  }

  Future<void> _checkPendingGuildRaidExpiries() async {
    if (!mounted || _checkingPendingGuildExpiries) return;
    _checkingPendingGuildExpiries = true;
    try {
      final pending =
          await ref.read(guildServiceProvider).pendingRaidExpiries();
      for (final info in pending) {
        if (!mounted) return;
        await _showAndAcknowledgeGuildRaidExpiry(info);
      }
    } catch (_) {
      // Non-blocking: expiry modals are retried by polling and lifecycle hooks.
    } finally {
      _checkingPendingGuildExpiries = false;
    }
  }

  Future<void> _showAndAcknowledgeGuildRaidExpiry(
    GuildRaidExpiredInfo info,
  ) async {
    if (!mounted) return;
    final key = info.guildRaidId.isNotEmpty
        ? info.guildRaidId
        : '${info.guildId}:${info.bossName}:expired';
    if (_guildExpiryInFlight.contains(key) ||
        _guildExpiryShownThisSession.contains(key)) {
      return;
    }

    _guildExpiryInFlight.add(key);
    ref.invalidate(guildProvider);
    ref.invalidate(guildRaidHistoryProvider);
    try {
      await showGuildRaidExpiredOverlay(context, info);
      _guildExpiryShownThisSession.add(key);
      if (!mounted || info.guildRaidId.isEmpty) return;
      try {
        await ref
            .read(guildServiceProvider)
            .acknowledgeRaidExpiry(info.guildRaidId);
      } catch (_) {
        // Keep the session guard; backend pending state can retry after restart.
      }
    } finally {
      _guildExpiryInFlight.remove(key);
    }
  }

  // ── journey card + menu ─────────────────────────────────────────────────
  void _toggleJourney() {
    final unlocks = ref.read(unlocksSnapshotProvider);
    if (!unlocks.isUnlocked(UnlockKeys.map)) {
      showLockedHint(context, UnlockKeys.map);
      return;
    }
    // First tap on a fresh Map button starts its tour; taps during the tour
    // open the journey card as usual.
    if (!_journeyOpen &&
        !FeatureTour.isRunning &&
        unlocks.isFresh(UnlockKeys.map)) {
      unawaited(_openUnlockedFeature(UnlockKeys.map));
      return;
    }
    setState(() => _journeyOpen = !_journeyOpen);
    if (_journeyOpen) WorldZoneRefreshNotifier.notify();
  }

  // ── guided unlocks ──────────────────────────────────────────────────────
  /// Nothing is on screen that an unlock ceremony would cover.
  bool _canShowUnlock() =>
      mounted &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      !_checkingLevelUps &&
      !_journeyOpen &&
      !homeBossReplayRunning &&
      !_bossReplayFetching &&
      _activeShellOverlay() == null;

  Future<void> _prepareUnlockCeremony(String key) async {
    if (!mounted) return;
    final switchingToHome = _tabIndex != 0;
    if (switchingToHome) setState(() => _tabIndex = 0);
    await WidgetsBinding.instance.endOfFrame;
    if (switchingToHome && mounted) {
      await Future<void>.delayed(
          AppMotion.duration(context, AppMotionTokens.micro));
    }
  }

  void _closeShellOverlays() {
    _journeyOpen = false;
    _worldOpen = false;
    _worldAutoOpenActive = false;
    _titlesOpen = false;
    _bossOpen = false;
    _guildOpen = false;
    _questsOpen = false;
    _seasonOpen = false;
    _talentsOpen = false;
    _achievementsOpen = false;
  }

  /// Opens an unlocked feature (Show me, or its first visit). Screens that
  /// open on their own run their tour through `TourOnFirstVisit`; features
  /// that live in the shell (Home, the Map button, the Gear and Mode tabs)
  /// run it here.
  Future<void> _openUnlockedFeature(String key, {bool replay = false}) async {
    if (!mounted) return;
    if (replay) UnlockReplay.pendingKey = key;
    switch (key) {
      case UnlockKeys.home:
      case UnlockKeys.map:
      case UnlockKeys.gear:
      case UnlockKeys.modes:
      case UnlockKeys.delve:
        final tab = switch (key) {
          UnlockKeys.gear => 'gear',
          UnlockKeys.modes || UnlockKeys.delve => 'modes',
          _ => 'home',
        };
        final changed =
            _navIds[_tabIndex] != tab || _activeShellOverlay() != null;
        setState(() {
          _closeShellOverlays();
          _tabIndex = _navIds.indexOf(tab);
        });
        if (changed) {
          await Future<void>.delayed(const Duration(milliseconds: 450));
        }
        UnlockReplay.pendingKey = null;
        if (mounted) await runUnlockTour(context, ref, key, replay: replay);
      case UnlockKeys.shields:
        await showStreakDetailSheet(context);
      case UnlockKeys.bosses:
        _onRingItemTap('boss');
      case UnlockKeys.ranks:
        _onRingItemTap('titles');
      case UnlockKeys.leaderboard:
        LeaderboardScreen.open(context);
      default:
        _onRingItemTap(key);
    }
  }

  /// A tab tap: locked tabs explain what opens them, and the first visit to
  /// a newly unlocked tab runs its tour.
  bool _guardTab(String tabId) {
    final unlocks = ref.read(unlocksSnapshotProvider);
    final key = switch (tabId) {
      'gear' => UnlockKeys.gear,
      'modes' => UnlockKeys.modes,
      _ => null,
    };
    if (key == null) return true;
    if (!unlocks.isUnlocked(key)) {
      showLockedHint(context, key);
      return false;
    }
    final tourKey = unlocks.isFresh(key)
        ? key
        : key == UnlockKeys.modes && unlocks.isFresh(UnlockKeys.delve)
            ? UnlockKeys.delve
            : null;
    if (tourKey != null) {
      unawaited(_openUnlockedFeature(tourKey));
      return false;
    }
    return true;
  }

  void _closeJourney() {
    if (!_journeyOpen) return;
    setState(() => _journeyOpen = false);
  }

  /// Sync from the journey card: jump to Home so the rewards land on the
  /// hero, then run the same flow as a pull.
  Future<void> _syncFromJourney() async {
    setState(() {
      _journeyOpen = false;
      _tabIndex = 0;
      _worldOpen = false;
      _titlesOpen = false;
      _bossOpen = false;
      _guildOpen = false;
      _questsOpen = false;
      _seasonOpen = false;
      _talentsOpen = false;
      _achievementsOpen = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await runPullImportFlow(context, ref);
  }

  Widget _screenFor(String id) {
    switch (id) {
      case 'home':
        return const HomeScreen();
      case 'quests':
        return const HomeScreen();
      case 'gear':
        return const GearScreen();
      // 'world' is never rendered inside the IndexedStack — tapping the nav
      // tab opens the shell overlay instead. This placeholder keeps index
      // alignment with _navIds.
      case 'world':
        return const SizedBox.shrink();
      case 'profile':
        return const ProfileScreen();
      case 'modes':
        return const ModesScreen();
      case 'titles':
        return const TitlesRanksScreen();
      case 'season':
        return const SeasonTrackScreen();
      case 'talents':
        return const TalentsScreen();
      case 'boss':
        return const BossScreen();
      case 'guild':
        return const GuildScreen();
      default:
        return Center(
          child: Text(id, style: const TextStyle(color: Colors.white38)),
        );
    }
  }

  Widget? _activeShellOverlay() {
    if (_worldOpen) {
      return WorldHubScreen(
        key: ValueKey(
          'world_$_worldAutoOpenActive'
          '_${_worldTargetRegionId ?? ''}_${_worldTargetZoneId ?? ''}',
        ),
        autoOpenActiveRegion: _worldAutoOpenActive,
        initialRegionId: _worldTargetRegionId,
        initialZoneId: _worldTargetZoneId,
        onClose: () => setState(() {
          _worldOpen = false;
          _worldAutoOpenActive = false;
          _worldTargetRegionId = null;
          _worldTargetZoneId = null;
          _pendingOnZoneSelected = null;
        }),
      );
    }
    if (_titlesOpen) {
      return TourOnFirstVisit(
        key: const ValueKey('titles'),
        unlockKey: UnlockKeys.ranks,
        child: TitlesRanksScreen(
          onClose: () => setState(() => _titlesOpen = false),
        ),
      );
    }
    if (_bossOpen) {
      return TourOnFirstVisit(
        key: const ValueKey('boss'),
        unlockKey: UnlockKeys.bosses,
        child: BossScreen(
          initialBossId: _pendingBossId,
          onClose: () => setState(() {
            _bossOpen = false;
            _pendingBossId = null;
          }),
        ),
      );
    }
    if (_guildOpen) {
      return TourOnFirstVisit(
        key: const ValueKey('guild'),
        unlockKey: UnlockKeys.guild,
        child: GuildScreen(
          onClose: () => setState(() => _guildOpen = false),
        ),
      );
    }
    if (_seasonOpen) {
      return SeasonTrackScreen(
        key: const ValueKey('season'),
        onClose: () => setState(() => _seasonOpen = false),
      );
    }
    if (_talentsOpen) {
      return TourOnFirstVisit(
        key: const ValueKey('talents'),
        unlockKey: UnlockKeys.talents,
        child: TalentsScreen(
          onClose: () => setState(() => _talentsOpen = false),
        ),
      );
    }
    if (_achievementsOpen) {
      return TourOnFirstVisit(
        key: const ValueKey('achievements'),
        unlockKey: UnlockKeys.achievements,
        child: AchievementsScreen(
          onClose: () => setState(() => _achievementsOpen = false),
        ),
      );
    }
    return null;
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    ref.listen(guildProvider, (previous, next) {
      if (!mounted) return;
      final guildId = next.valueOrNull?.id;
      if (guildId == _lastRealtimeGuildId) return;
      _lastRealtimeGuildId = guildId;
      unawaited(_guildRealtime.refreshGuildGroup());
      if (guildId != null) {
        _checkPendingGuildRaidVictories();
        _checkPendingGuildRaidExpiries();
      }
    });

    final unlocks = ref.watch(unlocksSnapshotProvider);

    return UnlockCoordinator(
      canInterrupt: _canShowUnlock,
      prepareCeremony: _prepareUnlockCeremony,
      openFeature: _openUnlockedFeature,
      child: Scaffold(
        backgroundColor: AppColors.shellBackground,
        body: LayoutBuilder(builder: (_, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final shellOverlay = _activeShellOverlay();

          return SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── tab content ─────────────────────────────────────────────
                Positioned.fill(
                  bottom: kNavBarH,
                  // Tabs covered by a shell overlay stop ticking, so idle
                  // motion pauses and boss-hit effects wait until the tab is
                  // visible again.
                  child: TickerMode(
                    enabled: shellOverlay == null,
                    child: ShellShake(
                      child: AppAnimatedIndexedStack(
                        index: _tabIndex.clamp(0, _navIds.length - 1),
                        children: _navIds.map(_screenFor).toList(),
                      ),
                    ),
                  ),
                ),

                // ── shell feature overlays ──────────────────────────────────
                Positioned.fill(
                  bottom: kNavBarH,
                  child: AnimatedSwitcher(
                    duration: AppMotion.duration(
                      context,
                      AppMotionTokens.sheetEnter,
                    ),
                    reverseDuration: AppMotion.duration(
                      context,
                      AppMotionTokens.sheetExit,
                    ),
                    switchInCurve: AppMotionTokens.enterCurve,
                    switchOutCurve: AppMotionTokens.exitCurve,
                    transitionBuilder: (child, animation) {
                      final faded = FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                      if (!AppMotion.isFull(context)) return faded;
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(.08, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: faded,
                      );
                    },
                    child: shellOverlay ??
                        const SizedBox.shrink(key: ValueKey('no-overlay')),
                  ),
                ),

                // ── journey card (from the Map button) ──────────────────────
                Positioned.fill(
                  child: JourneyPopover(
                    open: _journeyOpen,
                    onClose: _closeJourney,
                    onSync: _syncFromJourney,
                  ),
                ),

                // ── tab bar: Home · Gear · [Map] · Mode · Profile ───────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ShellTabBar(
                    currentIndex: _tabIndex.clamp(0, _navIds.length - 1),
                    mapOpen: _journeyOpen || _worldOpen,
                    locked: {
                      if (!unlocks.isUnlocked(UnlockKeys.gear))
                        _navIds.indexOf('gear'),
                      if (!unlocks.isUnlocked(UnlockKeys.modes))
                        _navIds.indexOf('modes'),
                    },
                    fresh: {
                      if (unlocks.isFresh(UnlockKeys.gear))
                        _navIds.indexOf('gear'),
                      if (unlocks.isFresh(UnlockKeys.modes) ||
                          unlocks.isFresh(UnlockKeys.delve))
                        _navIds.indexOf('modes'),
                    },
                    onTab: (i) {
                      if (!_guardTab(_navIds[i])) return;
                      setState(() {
                        _journeyOpen = false;
                        _tabIndex = i;
                        _worldOpen = false;
                        _titlesOpen = false;
                        _bossOpen = false;
                        _guildOpen = false;
                        _questsOpen = false;
                        _seasonOpen = false;
                        _talentsOpen = false;
                        _achievementsOpen = false;
                      });
                      if (_navIds[i] == 'home' || _navIds[i] == 'profile') {
                        ref.read(characterProfileProvider.notifier).refresh();
                        invalidateUserScopedProviders(ref);
                      }
                      if (_navIds[i] == 'modes') {
                        ref.invalidate(burnChainProvider);
                        ref.invalidate(delveStatusProvider);
                      }
                    },
                  ),
                ),

                // ── Map button (raised, mirrors the journey) ────────────────
                Positioned(
                  bottom: 34,
                  left: w / 2 - kMapOrbSize / 2,
                  child: MapOrbButton(
                    key: _mapNavKey,
                    open: _journeyOpen,
                    onTap: _toggleJourney,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _onRingItemTap(String id) {
    _closeJourney();
    if (id == 'burn_chain') {
      setState(() => _tabIndex = _navIds.indexOf('modes'));
      ModesScreen.openBurnChain(context);
      return;
    }
    if (id == 'quests' || id == 'rewards') {
      _openRewardsDialog();
      return;
    }
    if (id == 'chests') {
      Navigator.push(
          context, AppRoute(builder: (_) => const RegionChestsScreen()));
      return;
    }
    if (id == 'log') {
      Navigator.push(
          context, AppRoute(builder: (_) => const LogActivityScreen()));
      return;
    }
    if (id != 'achievements' && _achievementsOpen) {
      setState(() => _achievementsOpen = false);
    }
    if (id == 'achievements') {
      setState(() {
        _achievementsOpen = true;
        _worldOpen = false;
        _worldAutoOpenActive = false;
        _titlesOpen = false;
        _bossOpen = false;
        _guildOpen = false;
        _questsOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
      });
      return;
    }
    if (id == 'world') {
      WorldZoneRefreshNotifier.notify();
      final navIndex = _navIds.indexOf('world');
      setState(() {
        if (navIndex != -1) _tabIndex = navIndex;
        _pendingOnZoneSelected = null;
        _worldOpen = true;
        _worldAutoOpenActive = false;
        _titlesOpen = false;
        _bossOpen = false;
        _guildOpen = false;
        _questsOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
      });
      return;
    }
    if (id == 'titles') {
      setState(() {
        _titlesOpen = true;
        _guildOpen = false;
        _questsOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
      });
      return;
    }
    if (id == 'season') {
      setState(() {
        _seasonOpen = true;
        _talentsOpen = false;
        _titlesOpen = false;
        _bossOpen = false;
        _guildOpen = false;
        _questsOpen = false;
      });
      return;
    }
    if (id == 'talents') {
      setState(() {
        _talentsOpen = true;
        _seasonOpen = false;
        _titlesOpen = false;
        _bossOpen = false;
        _guildOpen = false;
        _questsOpen = false;
      });
      return;
    }
    if (id == 'boss') {
      setState(() {
        _bossOpen = true;
        _guildOpen = false;
        _questsOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
      });
      return;
    }
    if (id == 'guild') {
      final navIndex = _navIds.indexOf('guild');
      setState(() {
        if (navIndex != -1) {
          _tabIndex = navIndex;
          _guildOpen = false;
          _questsOpen = false;
          _seasonOpen = false;
          _talentsOpen = false;
        } else {
          _worldOpen = false;
          _titlesOpen = false;
          _bossOpen = false;
          _guildOpen = true;
          _questsOpen = false;
        }
      });
      return;
    }
    // If the id is already in the nav bar, switch to that tab.
    final navIndex = _navIds.indexOf(id);
    if (navIndex != -1) {
      setState(() {
        _tabIndex = navIndex;
        _guildOpen = false;
        _questsOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
      });
      return;
    }
    // Otherwise push the screen as a full-screen route.
    final screen = _screenFor(id);
    if (screen is Center) return; // placeholder — no screen yet
    Navigator.push(context, AppRoute(builder: (_) => screen));
  }
}
