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
import '../services/deep_link_notifier.dart';
import '../services/level_up_notifier.dart';
import '../services/item_obtained_notifier.dart';
import '../services/inventory_full_notifier.dart';
import '../widgets/level_up_overlay.dart';
import '../widgets/item_obtained_overlay.dart';
import '../widgets/inventory_full_overlay.dart';
import '../widgets/customize_ring_sheet.dart';
import '../../features/home/home_screen.dart';
import '../../features/login_reward/login_reward_screen.dart';
import '../../features/quests/quests_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/map/screens/world_hub_screen.dart';
import '../services/map_tab_notifier.dart';
import '../services/nav_tab_notifier.dart';
import '../services/world_map_notifier.dart';
import '../services/world_zone_refresh_notifier.dart';
import '../../features/integrations/providers/integrations_provider.dart';
import '../../features/notifications/services/notifications_service.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/titles/titles_ranks_screen.dart';
import '../../features/boss/screens/boss_screen.dart';
import '../../features/activity/models/activity_models.dart';
import '../../features/items/models/item_models.dart';
import '../../features/items/providers/items_provider.dart';
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
  bool _loginRewardShown = false;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  bool _wasOffline = false;
  StreamSubscription<Uri>? _deepLinkSub;
  bool _oauthCallbackHandled = false;

  late final AnimationController _openCtrl;
  late final Animation<double> _openAnim;

  final _authService = AuthService();

  late List<String> _ringIds;
  List<RingItem> get _ringItems => _ringIds
      .map((id) => kAllRingItems.firstWhere((e) => e.id == id))
      .toList();

  late List<String> _navIds;
  List<NavTab> get _navItems => _navIds
      .map((id) => kAllNavItems.firstWhere((e) => e.id == id))
      .toList();

  double get _snapStep =>
      _ringItems.isEmpty ? 60.0 : 360.0 / _ringItems.length;

  double _ringRotation = 0.0;
  double _snapFrom     = 0.0;
  double _snapTarget   = 0.0;
  double? _dragStartAngle;
  double  _rotationAtDragStart = 0.0;
  late final AnimationController _snapCtrl;

  late final AnimationController _hintCtrl;
  late final Animation<double>   _hintAnim;
  Timer? _hintTimer;
  late final StreamSubscription<LevelUpEvent> _levelUpSub;
  late final StreamSubscription<ItemDto> _itemObtainedSub;
  late final StreamSubscription<String> _navTabSub;
  late final StreamSubscription<WorldMapOpenRequest> _worldMapSub;
  late final StreamSubscription<BlockedItemInfo> _inventoryFullSub;
  late final StreamSubscription<Uri> _deepLinkNotifierSub;

  final _fabKey = GlobalKey();
  final _mapNavKey = GlobalKey();

  // LL-035 tutorial integration: hooked once, consumed every rebuild.
  bool _tutorialKeysRegistered = false;
  bool _tutorialHydrated = false;
  bool _introModalShown = false;
  bool _outroModalShown = false;
  VoidCallback? _tutorialListener;

  void _checkLoginReward(AsyncValue<Object?> profileAsync) {
    if (_loginRewardShown) return;
    // characterProfileProvider is AsyncNotifierProvider<_, CharacterProfile>
    // We access valueOrNull which may be null while loading.
    final profile = ref.read(characterProfileProvider).valueOrNull;
    if (profile == null) return;
    if (!profile.loginRewardAvailable) return;
    _loginRewardShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (ctx) => LoginRewardScreen(
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      );
    });
  }

  void _syncTutorialWithProfile() {
    if (_tutorialHydrated) return;
    final profile = ref.read(characterProfileProvider).valueOrNull;
    if (profile == null) return;
    _tutorialHydrated = true;
    final c = ref.read(tutorialControllerProvider);
    c.hydrateFromProfile(
      serverStep: profile.tutorialStep,
      serverTopicsSeen: profile.tutorialTopicsSeen,
    );
  }

  void _onTutorialStateChanged() {
    if (!mounted) return;
    final c = ref.read(tutorialControllerProvider);

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
      }
      _wasOffline = !isOnline;
    });
    _levelUpSub = LevelUpNotifier.stream.listen((event) async {
      if (!mounted) return;
      final oldIds = ref.read(inventoryProvider).valueOrNull?.items
          .map((i) => i.id).toSet() ?? {};
      showLevelUpScreen(context, event.newLevel, unlocks: event.unlocks);
      ref.invalidate(inventoryProvider);
      try {
        final newInventory = await ref.read(inventoryProvider.future);
        final newItems = newInventory.items
            .where((i) => !oldIds.contains(i.id))
            .toList();
        for (final item in newItems) {
          ItemObtainedNotifier.notify(item);
        }
      } catch (_) { /* silent — item popup is non-critical */ }
    });
    _itemObtainedSub = ItemObtainedNotifier.stream.listen((item) {
      if (mounted) showItemObtainedOverlay(context, item);
    });
    _navTabSub = NavTabNotifier.stream.listen((tabId) {
      final navIndex = _navIds.indexOf(tabId);
      if (navIndex != -1 && mounted) setState(() => _tabIndex = navIndex);
    });
    _worldMapSub = WorldMapNotifier.stream.listen((event) {
      if (!mounted) return;
      setState(() {
        _pendingOnZoneSelected = event.onZoneSelected;
        _worldOpen = true;
      });
    });
    _inventoryFullSub = InventoryFullNotifier.stream.listen((item) {
      if (mounted) {
        final level =
            ref.read(characterProfileProvider).valueOrNull?.level ?? 1;
        showInventoryFullOverlay(context, item, level);
      }
    });
    _ringIds = List.from(widget.initialRingIds ?? kDefaultRingIds);
    _navIds  = List.from(widget.initialNavIds  ?? kDefaultNavIds);

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

    // LL-035: attach once to the tutorial controller so intro/outro modals
    // are pushed as routes whenever the controller state requests them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = ref.read(tutorialControllerProvider);
      _tutorialListener = _onTutorialStateChanged;
      c.addListener(_tutorialListener!);
    });

    // FCM push notifications: request permission, fetch+register token,
    // attach listeners. Idempotent — safe to call on every shell mount.
    NotificationsService.instance.initialize(ref);

    _openCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _openAnim = CurvedAnimation(parent: _openCtrl, curve: Curves.easeOutBack);

    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _snapCtrl.addListener(() {
      final t = Curves.easeOutBack.transform(_snapCtrl.value);
      setState(() =>
          _ringRotation = _snapFrom + (_snapTarget - _snapFrom) * t);
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
      TweenSequenceItem(
          tween: ConstantTween(0.0),
          weight: 14),
    ]).animate(_hintCtrl);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'lifelevel' || uri.host != 'oauth') return;
    final code = uri.queryParameters['code'];
    if (code == null || !mounted) return;
    if (uri.pathSegments.contains('strava')) {
      if (_oauthCallbackHandled) return;
      _oauthCallbackHandled = true;
      _handleStravaCallback(code);
    }
  }

  void _handleStravaCallback(String code) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to Strava...')),
    );
    ref.read(integrationSyncProvider.notifier).connectStrava(code).then((error) async {
      _oauthCallbackHandled = false;
      await ref.read(integrationSyncProvider.notifier).refresh();
      if (!mounted) return;
      final connected = ref.read(integrationSyncProvider).isStravaConnected;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(connected
              ? 'Strava connected!'
              : 'Failed: ${error ?? 'unknown error'}'),
          duration: const Duration(seconds: 8),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _levelUpSub.cancel();
    _itemObtainedSub.cancel();
    _navTabSub.cancel();
    _worldMapSub.cancel();
    _inventoryFullSub.cancel();
    _connectivitySub.cancel();
    _deepLinkSub?.cancel();
    _deepLinkNotifierSub.cancel();
    _hintTimer?.cancel();
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
          setState(() {
            _ringIds = newRingIds;
            _navIds  = newNavIds;
            if (_tabIndex >= _navIds.length) _tabIndex = 0;
          });
          _authService.saveRingConfig(newRingIds);
        },
      ),
    );
  }

  void _onSpinStart(Offset globalPos) {
    _hintTimer?.cancel();
    _hintCtrl.stop();
    _hintCtrl.reset();
    _snapCtrl.stop();
    _dragStartAngle      = _angleFrom(globalPos, _fabGlobalCenter());
    _rotationAtDragStart = _ringRotation;
  }

  void _onSpinUpdate(Offset globalPos) {
    if (_dragStartAngle == null) return;
    double delta = _angleFrom(globalPos, _fabGlobalCenter()) - _dragStartAngle!;
    if (delta >  180) delta -= 360;
    if (delta < -180) delta += 360;
    setState(() => _ringRotation = _rotationAtDragStart + delta);
  }

  void _onSpinEnd() {
    _dragStartAngle = null;
    _snapFrom   = _ringRotation;
    _snapTarget = (_ringRotation / _snapStep).round() * _snapStep;
    if ((_snapTarget - _snapFrom).abs() < 0.5) return;
    _snapCtrl
      ..reset()
      ..forward();
  }

  Widget _screenFor(String id) {
    switch (id) {
      case 'home':    return const HomeScreen();
      case 'quests':  return const QuestsScreen();
      case 'map':     return const MapScreen();
      // 'world' is never rendered inside the IndexedStack — tapping the nav
      // tab opens the shell overlay instead. This placeholder keeps index
      // alignment with _navIds.
      case 'world':   return const SizedBox.shrink();
      case 'profile': return const ProfileScreen();
      case 'titles':  return const TitlesRanksScreen();
      case 'boss':    return const BossScreen();
      default:        return Center(
        child: Text(id, style: const TextStyle(color: Colors.white38)),
      );
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Listen for the first successful profile load to check login reward + hydrate tutorial.
    ref.listen(characterProfileProvider, (_, next) {
      _checkLoginReward(next);
      _syncTutorialWithProfile();
    });

    // Register shell-level tutorial targets once after the first frame paints
    // (needs _fabKey / _mapNavKey in the tree before the controller can read rects).
    if (!_tutorialKeysRegistered) {
      _tutorialKeysRegistered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = ref.read(tutorialControllerProvider);
        c.registerKey('bossFab', _fabKey);
        c.registerKey('logFab', _fabKey); // step 4 shares the FAB target
        c.registerKey('mapTab', _mapNavKey);
        _syncTutorialWithProfile();
      });
    }

    final angles = anglesFor(_ringItems.length);

    return Scaffold(
      backgroundColor: AppColors.shellBackground,
      body: LayoutBuilder(builder: (_, constraints) {
        final w     = constraints.maxWidth;
        final h     = constraints.maxHeight;
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
                    onClose: () => setState(() {
                      _worldOpen = false;
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
                    onClose: () => setState(() => _bossOpen = false),
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
                        color: Color.lerp(Colors.transparent,
                            kRadialScrim, _openCtrl.value),
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
                bottom: 0, left: 0, right: 0,
                child: ShellNavBar(
                  currentIndex: _tabIndex.clamp(0, _navItems.length - 1),
                  navTabs: _navItems,
                  keysByTabId: {'map': _mapNavKey},
                  onTap: (i) {
                    _closeRadial();
                    // 'world' in the nav bar opens the shell overlay instead
                    // of switching to a full tab, so every world-map entry
                    // point renders the same way.
                    if (_navIds[i] == 'world') {
                      WorldZoneRefreshNotifier.notify();
                      setState(() {
                        _pendingOnZoneSelected = null;
                        _worldOpen = true;
                      });
                      return;
                    }
                    setState(() { _tabIndex = i; _worldOpen = false; _titlesOpen = false; _bossOpen = false; });
                    if (_navIds[i] == 'home' || _navIds[i] == 'profile') {
                      ref.read(characterProfileProvider.notifier).refresh();
                      invalidateUserScopedProviders(ref);
                    }
                    if (_navIds[i] == 'map') {
                      MapTabNotifier.notify();
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
    if (id == 'world') {
      setState(() {
        _pendingOnZoneSelected = null;
        _worldOpen = true;
      });
      return;
    }
    if (id == 'titles') {
      setState(() => _titlesOpen = true);
      return;
    }
    if (id == 'boss') {
      setState(() => _bossOpen = true);
      return;
    }
    // If the id is already in the nav bar, switch to that tab.
    final navIndex = _navIds.indexOf(id);
    if (navIndex != -1) {
      setState(() => _tabIndex = navIndex);
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
    final rad  = actualAngle * pi / 180;
    final left = fabCx + cos(rad) * kRadius - kItemSize / 2;
    final top  = fabCy - sin(rad) * kRadius - kItemSize / 2;

    return Positioned(
      left: left,
      top:  top,
      child: Transform.scale(
        scale: _openAnim.value,
        child: Opacity(
          opacity: _openAnim.value.clamp(0.0, 1.0),
          child: GestureDetector(
            onTap:       () => _onRingItemTap(items[i].id),
            onPanStart:  (d) => _onSpinStart(d.globalPosition),
            onPanUpdate: (d) => _onSpinUpdate(d.globalPosition),
            onPanEnd:    (_) => _onSpinEnd(),
            onPanCancel: _onSpinEnd,
            child: RingItemTile(item: items[i]),
          ),
        ),
      ),
    );
  }
}
