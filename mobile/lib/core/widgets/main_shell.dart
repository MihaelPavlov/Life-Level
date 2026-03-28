import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../features/auth/auth_service.dart';
import '../services/level_up_notifier.dart';
import '../widgets/level_up_overlay.dart';
import 'customize_ring_sheet.dart';
import '../../features/home/home_screen.dart';
import '../../features/quests/quests_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/map/world_map_screen.dart';
import '../../features/profile/profile_screen.dart' show ProfileScreen, ProfileScreenState;

// ── constants ─────────────────────────────────────────────────────────────────
const _kNavBarH  = 82.0;
const _kFabSize  = 62.0;
const _kRadius   = 130.0;
const _kItemSize = 54.0;
const _kFabBottom = _kNavBarH - _kFabSize / 2;

/// Evenly-spaced angles for n items, starting at 30°.
/// For n=6: [30, 90, 150, 210, 270, 330] — matches the original layout.
List<double> anglesFor(int n) {
  if (n == 0) return [];
  final step = 360.0 / n;
  return List.generate(n, (i) => (30.0 + step * i) % 360);
}

// ── radial item data ──────────────────────────────────────────────────────────
class RingItem {
  final String id;
  final String emoji;
  final String label;
  final Color color;
  const RingItem(this.id, this.emoji, this.label, this.color);
}

const kAllRingItems = [
  RingItem('world',       '🌍', 'World',       Color(0xFF4f9eff)),
  RingItem('guild',       '🛡️', 'Guild',       Color(0xFFb08ce8)),
  RingItem('stats',       '📊', 'Stats',       Color(0xFF38d9c8)),
  RingItem('battle',      '⚔️', 'Battle',      Color(0xFFff8060)),
  RingItem('titles',      '🏅', 'Titles',      Color(0xFFe8b86d)),
  RingItem('boss',        '🐉', 'Boss',        Color(0xFFf85149)),
  RingItem('profile',     '👤', 'Profile',     Color(0xFF9e9e9e)),
  RingItem('leaderboard', '🏆', 'Leaderboard', Color(0xFFf5a623)),
  RingItem('map',         '🗺️', 'Map',         Color(0xFF52e0a0)),
  RingItem('quests',      '📜', 'Quests',      Color(0xFF8b949e)),
];

const _kDefaultRingIds = ['world', 'guild', 'stats', 'battle', 'titles', 'boss'];

// ── nav tab data ──────────────────────────────────────────────────────────────
class NavTab {
  final String id;
  final String emoji;
  final String label;
  const NavTab(this.id, this.emoji, this.label);
}

const kAllNavItems = [
  NavTab('home',        '🏠', 'Home'),
  NavTab('quests',      '📜', 'Quests'),
  NavTab('map',         '🗺️', 'Map'),
  NavTab('profile',     '👤', 'Profile'),
  NavTab('stats',       '📊', 'Stats'),
  NavTab('guild',       '🛡️', 'Guild'),
  NavTab('leaderboard', '🏆', 'Rankings'),
  NavTab('world',       '🌍', 'World'),
];

const _kDefaultNavIds = ['home', 'quests', 'map', 'profile'];

const _kNavBg     = Color(0xFF111830);
const _kNavBorder = Color(0xFF1e2d4a);
const _kCardBg    = Color(0xFF1a2848);

// ── shell ─────────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  final List<String>? initialRingIds;
  final List<String>? initialNavIds;
  const MainShell({super.key, this.initialRingIds, this.initialNavIds});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _tabIndex = 0;
  bool _radialOpen = false;
  bool _worldOpen = false;

  final _homeKey    = GlobalKey<HomeScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

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
  late final StreamSubscription<int> _levelUpSub;

  final _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _levelUpSub = LevelUpNotifier.stream.listen((newLevel) {
      if (mounted) showLevelUpScreen(context, newLevel);
    });
    _ringIds = List.from(widget.initialRingIds ?? _kDefaultRingIds);
    _navIds  = List.from(widget.initialNavIds  ?? _kDefaultNavIds);

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

  @override
  void dispose() {
    _levelUpSub.cancel();
    _hintTimer?.cancel();
    _openCtrl.dispose();
    _snapCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
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
    return rb.localToGlobal(const Offset(_kFabSize / 2, _kFabSize / 2));
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
      case 'home':        return HomeScreen(key: _homeKey);
      case 'quests':      return const QuestsScreen();
      case 'map':         return const MapScreen();
      case 'world':       return const WorldMapScreen();
      case 'profile':     return ProfileScreen(key: _profileKey);
      default:            return Center(
        child: Text(id, style: const TextStyle(color: Colors.white38)),
      );
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final angles = anglesFor(_ringItems.length);

    return Scaffold(
      backgroundColor: const Color(0xFF090d1a),
      body: LayoutBuilder(builder: (_, constraints) {
        final w    = constraints.maxWidth;
        final h    = constraints.maxHeight;
        final fabCx = w / 2;
        final fabCy = h - _kNavBarH;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── tab content ─────────────────────────────────────────────
              Positioned.fill(
                bottom: _kNavBarH,
                child: IndexedStack(
                  index: _tabIndex.clamp(0, _navIds.length - 1),
                  children: _navIds.map(_screenFor).toList(),
                ),
              ),

              // ── world map overlay ───────────────────────────────────────
              if (_worldOpen)
                Positioned.fill(
                  bottom: _kNavBarH,
                  child: WorldMapScreen(
                    onClose: () => setState(() => _worldOpen = false),
                  ),
                ),

              // ── backdrop ────────────────────────────────────────────────
              Positioned.fill(
                bottom: _kNavBarH,
                child: AnimatedBuilder(
                  animation: _openCtrl,
                  builder: (_, __) {
                    if (_openCtrl.value == 0) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: _closeRadial,
                      child: Container(
                        color: Color.lerp(Colors.transparent,
                            const Color(0xCC06080F), _openCtrl.value),
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
                child: _BottomNavBar(
                  currentIndex: _tabIndex.clamp(0, _navItems.length - 1),
                  navTabs: _navItems,
                  onTap: (i) {
                    _closeRadial();
                    setState(() { _tabIndex = i; _worldOpen = false; });
                    if (_navIds[i] == 'home')    _homeKey.currentState?.refresh();
                    if (_navIds[i] == 'profile') _profileKey.currentState?.refresh();
                  },
                ),
              ),

              // ── boss FAB ─────────────────────────────────────────────────
              Positioned(
                bottom: _kFabBottom,
                left: fabCx - _kFabSize / 2,
                child: _BossFab(
                  key: _fabKey,
                  isOpen: _radialOpen,
                  onTap: _toggleRadial,
                  onLongPress: _openCustomize,
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
      setState(() => _worldOpen = true);
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
    final left = fabCx + cos(rad) * _kRadius - _kItemSize / 2;
    final top  = fabCy - sin(rad) * _kRadius - _kItemSize / 2;

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
            child: _ItemTile(item: items[i]),
          ),
        ),
      ),
    );
  }
}

// ── item tile ─────────────────────────────────────────────────────────────────
class _ItemTile extends StatelessWidget {
  final RingItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  _kItemSize,
      height: _kItemSize,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withOpacity(0.65), width: 1.5),
        boxShadow: [
          BoxShadow(color: item.color.withOpacity(0.22), blurRadius: 16),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(item.label,
              style: TextStyle(
                  fontSize: 8,
                  color: item.color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ── boss FAB ──────────────────────────────────────────────────────────────────
class _BossFab extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BossFab({super.key, required this.isOpen, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: _kFabSize, height: _kFabSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isOpen
              ? const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1a2848), Color(0xFF1e3060)])
              : const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFff4040), Color(0xFFff8040)]),
          border: Border.all(
            color: isOpen
                ? const Color(0xFF4f9eff).withOpacity(0.5)
                : const Color(0xFFff7850).withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOpen
                  ? const Color(0xFF4f9eff).withOpacity(0.25)
                  : const Color(0xFFff503c).withOpacity(0.55),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isOpen
                  ? const Text('✕', key: ValueKey('x'),
                      style: TextStyle(fontSize: 22, color: Colors.white,
                          fontWeight: FontWeight.w300))
                  : const Text('⚔️', key: ValueKey('s'),
                      style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 1),
            Text(isOpen ? 'CLOSE' : 'BOSS',
                style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withOpacity(isOpen ? 0.6 : 0.85),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── bottom nav bar ────────────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<NavTab> navTabs;
  final ValueChanged<int> onTap;
  const _BottomNavBar({
    required this.currentIndex,
    required this.navTabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Split 4 tabs around the FAB gap (left 2, right 2).
    // If fewer/more than 4, split evenly with gap in centre.
    final half = navTabs.length ~/ 2;
    final left  = navTabs.sublist(0, half);
    final right = navTabs.sublist(half);

    return Container(
      height: _kNavBarH,
      decoration: const BoxDecoration(
        color: _kNavBg,
        border: Border(top: BorderSide(color: _kNavBorder)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < left.length; i++)
            _NavItem(
              tab: left[i],
              active: currentIndex == i,
              onTap: () => onTap(i),
            ),
          const Expanded(child: SizedBox()),
          for (int i = 0; i < right.length; i++)
            _NavItem(
              tab: right[i],
              active: currentIndex == half + i,
              onTap: () => onTap(half + i),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavTab tab;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const activeColor   = Color(0xFF4f9eff);
    const inactiveColor = Color(0xFF6e84b0);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tab.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(tab.label,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? activeColor : inactiveColor)),
            ],
          ),
        ),
      ),
    );
  }
}
