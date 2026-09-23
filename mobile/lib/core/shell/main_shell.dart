import 'dart:async';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/character/providers/character_provider.dart';
import '../session/invalidate_user_providers.dart';
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
import '../widgets/customize_ring_sheet.dart';
import '../../features/home/home_screen.dart';
import '../../features/achievements/achievements_screen.dart';
import '../../features/home/providers/world_progress_provider.dart';
import '../../features/login_reward/login_reward_screen.dart';
import '../../features/gear/gear_screen.dart';
import '../../features/map/screens/world_hub_screen.dart';
import '../services/nav_tab_notifier.dart';
import '../services/shell_overlay_notifier.dart';
import '../services/world_map_notifier.dart';
import '../services/world_zone_refresh_notifier.dart';
import '../../features/integrations/providers/integrations_provider.dart';
import '../../features/notifications/services/notifications_service.dart';
import '../../features/profile/profile_screen.dart';
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
import '../../features/character/models/character_profile.dart';
import '../../features/items/models/item_models.dart';
import '../../features/items/providers/items_provider.dart';
import '../widgets/app_toast.dart';
import 'shell_constants.dart';
import 'shell_models.dart';
import 'widgets/ring_item_tile.dart';
import 'widgets/boss_fab.dart';
import 'widgets/bottom_nav_bar.dart';
import '../../features/tutorial/providers/tutorial_provider.dart';
import '../../features/tutorial/widgets/tutorial_overlay.dart';
import '../../features/tutorial/screens/tutorial_intro_screen.dart';
import '../../features/tutorial/screens/tutorial_outro_screen.dart';

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
  bool _radialOpen = false;
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
  bool _loginRewardShown = false;
  bool _worldAutoOpenActive = false;
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

  late final AnimationController _openCtrl;
  late final Animation<double> _openAnim;

  final _authService = AuthService();
  final _guildRealtime = GuildRealtimeService();

  late List<String> _ringIds;
  List<RingItem> get _ringItems => sanitizeRingIds(_ringIds)
      .map((id) => kAllRingItems.firstWhere((e) => e.id == id))
      .toList();

  late List<String> _navIds;
  List<NavTab> get _navItems => sanitizeNavIds(_navIds)
      .map((id) => kAllNavItems.firstWhere((e) => e.id == id))
      .toList();

  double get _snapStep => _ringItems.isEmpty ? 60.0 : 360.0 / _ringItems.length;

  double _ringRotation = 0.0;
  double _snapFrom = 0.0;
  double _snapTarget = 0.0;
  double? _dragStartAngle;
  double _rotationAtDragStart = 0.0;
  late final AnimationController _snapCtrl;

  late final AnimationController _hintCtrl;
  late final Animation<double> _hintAnim;
  Timer? _hintTimer;
  Timer? _guildVictoryPollTimer;
  Timer? _guildExpiryPollTimer;
  late final StreamSubscription<LevelUpEvent> _levelUpSub;
  late final StreamSubscription<ItemDto> _itemObtainedSub;
  late final StreamSubscription<String> _navTabSub;
  late final StreamSubscription<String> _shellOverlaySub;
  late final StreamSubscription<WorldMapOpenRequest> _worldMapSub;
  late final StreamSubscription<BlockedItemInfo> _inventoryFullSub;
  late final StreamSubscription<DungeonFloorClearedEvent> _dungeonFloorSub;
  late final StreamSubscription<GuildRaidVictoryInfo> _guildRaidVictorySub;
  late final StreamSubscription<BossOpenIntent> _bossOverlaySub;
  late final StreamSubscription<BossDefeatedInfo> _bossDefeatedSub;
  late final StreamSubscription<Uri> _deepLinkNotifierSub;
  late final StreamSubscription<NotificationBannerPayload>
      _notificationBannerSub;

  final _fabKey = GlobalKey();
  final _mapNavKey = GlobalKey();

  // LL-035 tutorial integration: hooked once, consumed every rebuild.
  bool _tutorialKeysRegistered = false;
  bool _introModalShown = false;
  bool _outroModalShown = false;
  VoidCallback? _tutorialListener;
  int? _lastTutorialServerStep;
  int? _lastTutorialTopicsSeen;
  int? _lastMapTutorialStep;

  void _checkLoginReward(CharacterProfile? profile) {
    if (!mounted) return;
    if (_loginRewardShown) return;
    if (profile == null) return;
    if (!profile.loginRewardAvailable) return;
    _loginRewardShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showRewardsSheet(context);
    });
  }

  void _openRewardsDialog() {
    if (!mounted) return;
    showRewardsSheet(context);
  }

  void _syncTutorialWithProfile([CharacterProfile? profile]) {
    if (!mounted) return;
    profile ??= ref.read(characterProfileProvider).valueOrNull;
    if (profile == null) return;
    final serverStep = profile.tutorialStep;
    final serverTopicsSeen = profile.tutorialTopicsSeen;
    final mapTutorialStep = profile.mapTutorialStep;
    if (_lastTutorialServerStep == serverStep &&
        _lastTutorialTopicsSeen == serverTopicsSeen &&
        _lastMapTutorialStep == mapTutorialStep) {
      return;
    }
    _lastTutorialServerStep = serverStep;
    _lastTutorialTopicsSeen = serverTopicsSeen;
    _lastMapTutorialStep = mapTutorialStep;
    final c = ref.read(tutorialControllerProvider);
    c.hydrateFromProfile(
      serverStep: serverStep,
      serverTopicsSeen: serverTopicsSeen,
      mapTutorialStep: mapTutorialStep,
    );
  }

  void _onTutorialStateChanged() {
    if (!mounted) return;
    final c = ref.read(tutorialControllerProvider);

    if (c.isMapTutorial && c.step != null && !_worldOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
        WorldZoneRefreshNotifier.notify();
      });
    }

    if (c.shouldShowIntroModal && !_introModalShown) {
      _introModalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TutorialIntroScreen(),
            fullscreenDialog: true,
          ),
        );
        _introModalShown = false;
        // Dismiss in the controller if the user pressed back without tapping
        // BEGIN — prevents a stale shouldShowIntroModal == true from causing
        // a premature re-push the next time replayAll() notifies.
        if (mounted) {
          final ctrl = ref.read(tutorialControllerProvider);
          if (ctrl.shouldShowIntroModal) ctrl.dismissIntroModal();
        }
      });
    }
    if (c.shouldShowOutroModal && !_outroModalShown) {
      _outroModalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TutorialOutroScreen(),
            fullscreenDialog: true,
          ),
        );
        _outroModalShown = false;
      });
    }
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
    _levelUpSub = LevelUpNotifier.stream.listen((event) async {
      if (!mounted) return;
      final oldIds = ref
              .read(inventoryProvider)
              .valueOrNull
              ?.items
              .map((i) => i.id)
              .toSet() ??
          {};
      showLevelUpScreen(context, event.newLevel, unlocks: event.unlocks);
      ref.invalidate(inventoryProvider);
      try {
        final newInventory = await ref.read(inventoryProvider.future);
        final newItems =
            newInventory.items.where((i) => !oldIds.contains(i.id)).toList();
        for (final item in newItems) {
          ItemObtainedNotifier.notify(item);
        }
      } catch (_) {/* silent — item popup is non-critical */}
    });
    _itemObtainedSub = ItemObtainedNotifier.stream.listen((item) {
      if (mounted) showItemObtainedOverlay(context, item);
    });
    _navTabSub = NavTabNotifier.stream.listen((tabId) {
      if (!mounted) return;
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
    _worldMapSub = WorldMapNotifier.stream.listen((event) {
      if (!mounted) return;
      WorldZoneRefreshNotifier.notify();
      final navIndex = _navIds.indexOf('world');
      setState(() {
        if (navIndex != -1) _tabIndex = navIndex;
        _pendingOnZoneSelected = event.onZoneSelected;
        _worldOpen = true;
        _worldAutoOpenActive = event.autoOpenActiveRegion;
        _titlesOpen = false;
        _bossOpen = false;
        _guildOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
      });
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
        _radialOpen = false;
        _worldOpen = false;
        _titlesOpen = false;
        _bossOpen = true;
        _guildOpen = false;
        _seasonOpen = false;
        _talentsOpen = false;
        _pendingBossId = intent.bossId;
      });
    });
    _ringIds = sanitizeRingIds(widget.initialRingIds);
    _navIds = sanitizeNavIds(widget.initialNavIds);

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

    // LL-035: attach once to the tutorial controller so intro/outro modals
    // are pushed as routes whenever the controller state requests them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = ref.read(tutorialControllerProvider);
      _tutorialListener = _onTutorialStateChanged;
      c.addListener(_tutorialListener!);
      _onTutorialStateChanged();
    });

    // FCM push notifications: request permission, fetch+register token,
    // attach listeners. Idempotent — safe to call on every shell mount.
    NotificationsService.instance.initialize(ref);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startGuildRealtime());
      _checkPendingGuildRaidVictories();
      _checkPendingGuildRaidExpiries();
    });
    _guildVictoryPollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkPendingGuildRaidVictories(),
    );
    _guildExpiryPollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkPendingGuildRaidExpiries(),
    );

    _openCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _openAnim = CurvedAnimation(parent: _openCtrl, curve: Curves.easeOutBack);

    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _snapCtrl.addListener(() {
      final t = Curves.easeOutBack.transform(_snapCtrl.value);
      setState(() => _ringRotation = _snapFrom + (_snapTarget - _snapFrom) * t);
    });

    _hintCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3400));
    _hintAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -14.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: -14.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -7.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 15),
      TweenSequenceItem(
          tween: Tween(begin: -7.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 15),
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -3.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 8),
      TweenSequenceItem(
          tween: Tween(begin: -3.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInOutSine)),
          weight: 8),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 14),
    ]).animate(_hintCtrl);
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
        _oauthCallbackHandled = true;
        _handleStravaCallback(code);
      }
      return;
    }

    // ── Notification deep links ────────────────────────────────────────────
    switch (uri.host) {
      case 'home':
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
          _radialOpen = false;
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
          _radialOpen = false;
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
          _radialOpen = false;
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
          _radialOpen = false;
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
    _itemObtainedSub.cancel();
    _dungeonFloorSub.cancel();
    _guildRaidVictorySub.cancel();
    _bossOverlaySub.cancel();
    _bossDefeatedSub.cancel();
    _navTabSub.cancel();
    _shellOverlaySub.cancel();
    _worldMapSub.cancel();
    _inventoryFullSub.cancel();
    _connectivitySub.cancel();
    _deepLinkSub?.cancel();
    _deepLinkNotifierSub.cancel();
    _notificationBannerSub.cancel();
    unawaited(_guildRealtime.stop());
    _hintTimer?.cancel();
    _guildVictoryPollTimer?.cancel();
    _guildExpiryPollTimer?.cancel();
    _openCtrl.dispose();
    _snapCtrl.dispose();
    _hintCtrl.dispose();
    if (_tutorialListener != null) {
      ref.read(tutorialControllerProvider).removeListener(_tutorialListener!);
    }
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
    }
  }

  Future<void> _triggerForegroundHealthSync() async {
    final syncState = ref.read(integrationSyncProvider);
    if (!syncState.isHealthConnected || syncState.isSyncing) return;

    // Only sync if more than 15 minutes have passed since the last sync
    final lastSync = syncState.lastSyncAt;
    if (lastSync != null &&
        DateTime.now().difference(lastSync).inMinutes < 15) {
      return;
    }

    ref.read(integrationSyncProvider.notifier).syncNow();
  }

  void _invalidateAllProviders() {
    if (!mounted) return;
    invalidateUserScopedProviders(ref);
  }

  Future<void> _startGuildRealtime() async {
    await _guildRealtime.start(
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

  // ── open / close ──────────────────────────────────────────────────────────
  void _toggleRadial() {
    setState(() => _radialOpen = !_radialOpen);
    if (_radialOpen) {
      _openCtrl.forward();
      _hintTimer?.cancel();
      _hintTimer = Timer(const Duration(milliseconds: 500), () {
        if (_radialOpen && _dragStartAngle == null) {
          _hintCtrl.forward(from: 0);
        }
      });
    } else {
      _openCtrl.reverse();
      _hintTimer?.cancel();
      _hintCtrl.stop();
      _hintCtrl.reset();
    }
  }

  void _closeRadial() {
    if (!_radialOpen) return;
    setState(() => _radialOpen = false);
    _openCtrl.reverse();
    _hintTimer?.cancel();
    _hintCtrl.stop();
    _hintCtrl.reset();
  }

  // ── spin helpers ──────────────────────────────────────────────────────────
  Offset _fabGlobalCenter() {
    final rb = _fabKey.currentContext!.findRenderObject() as RenderBox;
    return rb.localToGlobal(const Offset(kFabSize / 2, kFabSize / 2));
  }

  double _angleFrom(Offset global, Offset centre) {
    final dx = global.dx - centre.dx;
    final dy = -(global.dy - centre.dy);
    return (atan2(dy, dx) * 180 / pi + 360) % 360;
  }

  void _openCustomize() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomizeRingSheet(
        currentIds: List.from(_ringIds),
        currentNavIds: List.from(_navIds),
        onSave: (newRingIds, newNavIds) {
          final sanitizedRingIds = sanitizeRingIds(newRingIds);
          final sanitizedNavIds = sanitizeNavIds(newNavIds);
          setState(() {
            _ringIds = sanitizedRingIds;
            _navIds = sanitizedNavIds;
            if (_tabIndex >= _navIds.length) _tabIndex = 0;
          });
          _authService.saveRingConfig(sanitizedRingIds);
        },
      ),
    );
  }

  void _onSpinStart(Offset globalPos) {
    _hintTimer?.cancel();
    _hintCtrl.stop();
    _hintCtrl.reset();
    _snapCtrl.stop();
    _dragStartAngle = _angleFrom(globalPos, _fabGlobalCenter());
    _rotationAtDragStart = _ringRotation;
  }

  void _onSpinUpdate(Offset globalPos) {
    if (_dragStartAngle == null) return;
    double delta = _angleFrom(globalPos, _fabGlobalCenter()) - _dragStartAngle!;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    setState(() => _ringRotation = _rotationAtDragStart + delta);
  }

  void _onSpinEnd() {
    _dragStartAngle = null;
    _snapFrom = _ringRotation;
    _snapTarget = (_ringRotation / _snapStep).round() * _snapStep;
    if ((_snapTarget - _snapFrom).abs() < 0.5) return;
    _snapCtrl
      ..reset()
      ..forward();
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

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Listen for the first successful profile load to check login reward + hydrate tutorial.
    ref.listen(characterProfileProvider, (_, next) {
      if (!mounted) return;
      final profile = next.valueOrNull;
      _checkLoginReward(profile);
      _syncTutorialWithProfile(profile);
    });
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

    // Register shell-level tutorial targets once after the first frame paints
    // (needs _fabKey / _mapNavKey in the tree before the controller can read rects).
    if (!_tutorialKeysRegistered) {
      _tutorialKeysRegistered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = ref.read(tutorialControllerProvider);
        c.registerKey('bossFab', _fabKey);
        c.registerKey('mapTab', _mapNavKey);
        _syncTutorialWithProfile();
      });
    }

    final angles = anglesFor(_ringItems.length);

    return Scaffold(
      backgroundColor: AppColors.shellBackground,
      body: LayoutBuilder(builder: (_, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final fabCx = w / 2;
        final fabCy = h - kNavBarH;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── tab content ─────────────────────────────────────────────
              Positioned.fill(
                bottom: kNavBarH,
                child: IndexedStack(
                  index: _tabIndex.clamp(0, _navIds.length - 1),
                  children: _navIds.map(_screenFor).toList(),
                ),
              ),

              // ── world map overlay ───────────────────────────────────────
              // Note: the new WorldHubScreen uses push-based region navigation
              // instead of the old onZoneSelected callback. Legacy callers
              // (e.g. MapScreen._openWorldMap) will lose the pick-a-zone
              // shortcut; to be reworked when the local-map is migrated.
              if (_worldOpen)
                Positioned.fill(
                  bottom: kNavBarH,
                  child: WorldHubScreen(
                    key: ValueKey('world_$_worldAutoOpenActive'),
                    autoOpenActiveRegion: _worldAutoOpenActive,
                    onClose: () => setState(() {
                      _worldOpen = false;
                      _worldAutoOpenActive = false;
                      _pendingOnZoneSelected = null;
                    }),
                  ),
                ),

              // ── titles & ranks overlay ───────────────────────────────────
              if (_titlesOpen)
                Positioned.fill(
                  bottom: kNavBarH,
                  child: TitlesRanksScreen(
                    onClose: () => setState(() => _titlesOpen = false),
                  ),
                ),

              // ── boss overlay ───────────────────────────────────────────
              if (_bossOpen)
                Positioned.fill(
                  bottom: kNavBarH,
                  child: BossScreen(
                    initialBossId: _pendingBossId,
                    onClose: () => setState(() {
                      _bossOpen = false;
                      _pendingBossId = null;
                    }),
                  ),
                ),

              // ── guild overlay ──────────────────────────────────────────
              if (_guildOpen)
                Positioned.fill(
                  bottom: kNavBarH,
                  child: GuildScreen(
                    onClose: () => setState(() => _guildOpen = false),
                  ),
                ),

              // ── season overlay ─────────────────────────────────────────
              if (_seasonOpen)
                Positioned.fill(
                  bottom: kNavBarH,
                  child: SeasonTrackScreen(
                    onClose: () => setState(() => _seasonOpen = false),
                  ),
                ),

              // ── talents overlay ────────────────────────────────────────
              if (_talentsOpen)
                Positioned.fill(
                  bottom: kNavBarH,
                  child: TalentsScreen(
                    onClose: () => setState(() => _talentsOpen = false),
                  ),
                ),

              // ── achievements overlay ───────────────────────────────────
              if (_achievementsOpen)
                Positioned.fill(
                  bottom: kNavBarH,
                  child: AchievementsScreen(
                    onClose: () => setState(() => _achievementsOpen = false),
                  ),
                ),

              // ── backdrop ────────────────────────────────────────────────
              Positioned.fill(
                bottom: kNavBarH,
                child: AnimatedBuilder(
                  animation: _openCtrl,
                  builder: (_, __) {
                    if (_openCtrl.value == 0) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: _closeRadial,
                      child: Container(
                        color: Color.lerp(
                            Colors.transparent, kRadialScrim, _openCtrl.value),
                      ),
                    );
                  },
                ),
              ),

              // ── ring items ───────────────────────────────────────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_openCtrl, _hintCtrl]),
                  builder: (_, __) {
                    if (_openCtrl.value == 0) return const SizedBox.shrink();
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int i = 0; i < _ringItems.length; i++)
                          _buildItem(i, angles, fabCx, fabCy),
                      ],
                    );
                  },
                ),
              ),

              // ── nav bar ──────────────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ShellNavBar(
                  currentIndex: _tabIndex.clamp(0, _navItems.length - 1),
                  navTabs: _navItems,
                  keysByTabId: {'world': _mapNavKey},
                  onTap: (i) {
                    _closeRadial();
                    // 'world' opens the shell overlay AND advances the tab
                    // index so the bottom nav highlights it. The IndexedStack
                    // slot for 'world' renders SizedBox.shrink() beneath the
                    // overlay, so the tab-index switch is purely cosmetic.
                    if (_navIds[i] == 'world') {
                      WorldZoneRefreshNotifier.notify();
                      setState(() {
                        _pendingOnZoneSelected = null;
                        _tabIndex = i;
                        _worldOpen = true;
                        _worldAutoOpenActive = true;
                        _titlesOpen = false;
                        _bossOpen = false;
                        _guildOpen = false;
                        _questsOpen = false;
                        _seasonOpen = false;
                        _talentsOpen = false;
                        _achievementsOpen = false;
                      });
                      return;
                    }
                    setState(() {
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
                  },
                ),
              ),

              // ── boss FAB ─────────────────────────────────────────────────
              Positioned(
                bottom: kFabBottom,
                left: fabCx - kFabSize / 2,
                child: BossFab(
                  key: _fabKey,
                  isOpen: _radialOpen,
                  onTap: _toggleRadial,
                  onLongPress: _openCustomize,
                ),
              ),

              // ── LL-035 tutorial overlay (topmost) ────────────────────────
              const Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: TutorialOverlay(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _onRingItemTap(String id) {
    _closeRadial();
    if (id == 'quests' || id == 'rewards') {
      _openRewardsDialog();
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildItem(int i, List<double> angles, double fabCx, double fabCy) {
    final items = _ringItems;
    if (i >= items.length || i >= angles.length) return const SizedBox.shrink();
    final actualAngle = (angles[i] + _ringRotation + _hintAnim.value) % 360;
    final rad = actualAngle * pi / 180;
    final left = fabCx + cos(rad) * kRadius - kItemSize / 2;
    final top = fabCy - sin(rad) * kRadius - kItemSize / 2;

    return Positioned(
      left: left,
      top: top,
      child: Transform.scale(
        scale: _openAnim.value,
        child: Opacity(
          opacity: _openAnim.value.clamp(0.0, 1.0),
          child: GestureDetector(
            onTap: () => _onRingItemTap(items[i].id),
            onPanStart: (d) => _onSpinStart(d.globalPosition),
            onPanUpdate: (d) => _onSpinUpdate(d.globalPosition),
            onPanEnd: (_) => _onSpinEnd(),
            onPanCancel: _onSpinEnd,
            child: RingItemTile(item: items[i]),
          ),
        ),
      ),
    );
  }
}
