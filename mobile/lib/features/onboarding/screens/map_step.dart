import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/avatar_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/services/pending_welcome.dart';
import '../../../core/shell/main_shell.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/widgets/app_toast.dart';
import '../../map/models/world_map_models.dart';
import '../../map/services/world_zone_service.dart';
import '../../map/widgets/map_icon_resolver.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_ui.dart';

/// Step 8 — "Chapter opening". The region's trail recedes into the forest
/// behind the hero; imported distance fills the road stop by stop while the
/// camera flies to each zone it reaches, then pulls back to show where the
/// hero stands. "Enter the world" saves the character, sets the reached stop
/// as the destination (which spends the km) and zooms into it.
class MapStep extends StatefulWidget {
  const MapStep({super.key});

  @override
  State<MapStep> createState() => _MapStepState();
}

// ── Plan & timeline ──────────────────────────────────────────────────────────

class _Plan {
  final RegionDetail region;
  final List<ZoneNode> trail; // current zone first
  final double banked;
  final int reachIndex; // index into [trail] the banked km reaches
  final double walkedKm;

  const _Plan(
      this.region, this.trail, this.banked, this.reachIndex, this.walkedKm);

  ZoneNode get target => trail[reachIndex];
  ZoneNode? get next =>
      reachIndex + 1 < trail.length ? trail[reachIndex + 1] : null;
  bool get blocked =>
      reachIndex > 0 &&
      (target.isChest || target.isDungeon || target.isBoss || target.isCrossroads);
  double get left => banked - walkedKm;

  /// Km shown on the counters at fractional stop [progress].
  double kmAt(double progress) {
    final i = progress.floor().clamp(0, reachIndex);
    final f = progress - i;
    return kmTo(i) + (i + 1 <= reachIndex ? f * trail[i + 1].distanceKm : 0);
  }

  /// Km walked to reach stop [i] (cumulative).
  double kmTo(int i) {
    var km = 0.0;
    for (var j = 1; j <= i && j < trail.length; j++) {
      km += trail[j].distanceKm;
    }
    return km;
  }
}

/// Every beat of the screen, in milliseconds from the moment the map loads.
class _Timeline {
  static const firstMove = 1800.0;
  static const hold = 600.0;
  static const arrivePop = 450.0;

  final List<double> start; // move start per stop (index 0 unused)
  final List<double> arrive; // arrival per stop (index 0 unused)
  final double pullAt; // camera starts pulling back to the whole trail
  final double ctaAt;
  final double total;

  const _Timeline(this.start, this.arrive, this.pullAt, this.ctaAt, this.total);

  factory _Timeline.of(_Plan plan) {
    final start = <double>[0], arrive = <double>[0];
    var t = firstMove;
    for (var i = 1; i <= plan.reachIndex; i++) {
      final move =
          (600 + 400 * plan.trail[i].distanceKm).clamp(1000.0, 1800.0);
      start.add(t);
      arrive.add(t + move);
      t += move + hold;
    }
    if (plan.reachIndex == 0) {
      return _Timeline(start, arrive, double.infinity, 1900, 2300);
    }
    final pull = arrive.last + 500;
    return _Timeline(start, arrive, pull, pull + 700, pull + 1100);
  }

  int get reach => arrive.length - 1;

  /// Fractional stop progress: 1.5 = halfway from stop 1 to stop 2.
  double progress(double ms) {
    for (var i = reach; i >= 1; i--) {
      if (ms >= arrive[i]) return i.toDouble();
      if (ms >= start[i]) {
        return i - 1 + _ease((ms - start[i]) / (arrive[i] - start[i]));
      }
    }
    return 0;
  }

  bool moving(double ms) {
    for (var i = 1; i <= reach; i++) {
      if (ms > start[i] && ms < arrive[i]) return true;
    }
    return false;
  }

  /// 0→1 pop for the arrival at stop [i]; 0 before it is reached.
  double arrival(int i, double ms) =>
      i >= 1 && i <= reach ? _cl((ms - arrive[i]) / arrivePop) : 0;

  bool reached(int i, double ms) => i >= 1 && i <= reach && ms >= arrive[i];
}

double _cl(double x) => x.clamp(0.0, 1.0);
double _ease(double x) => Curves.easeInOutCubic.transform(_cl(x));
double _out(double x) => Curves.easeOutCubic.transform(_cl(x));
double _back(double x) => Curves.easeOutBack.transform(_cl(x));

// ── Stage geometry ───────────────────────────────────────────────────────────

/// The perspective trail laid out for a screen size. Coordinates come from
/// the 390×844 design and scale with the screen.
class _Stage {
  static const _start = Offset(195, 566);
  static const _slots = [
    Offset(250, 474),
    Offset(175, 397),
    Offset(231, 341),
    Offset(185, 304),
    Offset(201, 272),
  ];
  static const _sizes = [68.0, 52.0, 40.0, 30.0, 22.0];
  static const _depthOpacity = [1.0, 1.0, .75, .65, .5];

  final Size size;
  final double sx, sy, s;
  final List<Offset> points; // [0] = starting zone, [i] = stop i
  final Path path;
  final ui.PathMetric metric;
  final List<double> stops; // arc length at each point

  _Stage._(this.size, this.sx, this.sy, this.s, this.points, this.path,
      this.metric, this.stops);

  factory _Stage(Size size, int count) {
    final sx = size.width / 390, sy = size.height / 844;
    final s = math.min(sx, sy);
    Offset p(Offset o) => Offset(o.dx * sx, o.dy * sy);
    final n = math.min(count, _slots.length + 1);
    final points = [p(_start), for (var i = 1; i < n; i++) p(_slots[i - 1])];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    final stops = <double>[0];
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final dy = a.dy - b.dy;
      final seg = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, a.dy - dy * .55, b.dx, b.dy + dy * .45, b.dx, b.dy);
      path.cubicTo(a.dx, a.dy - dy * .55, b.dx, b.dy + dy * .45, b.dx, b.dy);
      stops.add(stops.last + seg.computeMetrics().first.length);
    }
    final metric = points.length > 1
        ? path.computeMetrics().first
        : (Path()
              ..moveTo(points.first.dx, points.first.dy)
              ..lineTo(points.first.dx, points.first.dy - 1))
            .computeMetrics()
            .first;
    return _Stage._(size, sx, sy, s, points, path, metric, stops);
  }

  int get count => points.length;
  Offset get focus => Offset(size.width / 2, size.height / 2);
  double nodeSize(int i) => i == 0 ? 72 * s : _sizes[i - 1] * s;
  double depthOpacity(int i) => i == 0 ? 1 : _depthOpacity[i - 1];
  double get length => stops.last;

  /// Camera zoom when centred on stop [i]: deeper stops sit further away.
  double zoomFor(int i) => math.min(1.5 + .15 * (i - 1), 1.9);

  double lengthAt(double progress) {
    if (count < 2) return 0;
    final i = progress.floor().clamp(0, count - 2);
    final f = progress - i;
    return stops[i] + (stops[i + 1] - stops[i]) * f;
  }
}

/// Where the camera looks ([c], in stage coordinates) and how close ([z]).
class _Cam {
  final Offset c;
  final double z;
  const _Cam(this.c, this.z);

  static _Cam mix(_Cam a, _Cam b, double f) => _Cam(
        Offset.lerp(a.c, b.c, f)!,
        // A slight pull-out mid-move reads as a short flight between zones.
        a.z + (b.z - a.z) * f - .15 * math.sin(math.pi * f),
      );

  Matrix4 matrix(Offset focus) => Matrix4.translationValues(
      focus.dx - z * c.dx, focus.dy - z * c.dy, 0)
    ..multiply(Matrix4.diagonal3Values(z, z, 1));

  Offset project(Offset p, Offset focus) => focus + (p - c) * z;
}

// ── Screen ───────────────────────────────────────────────────────────────────

class _MapStepState extends State<MapStep> with TickerProviderStateMixin {
  static const _visible = 6;

  late final _t = AnimationController(vsync: this)..addListener(_onTick);
  late final _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  late final _exit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  _Plan? _plan;
  _Timeline? _tl;
  String? _error;
  int _arrived = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (onboardingMotion(context)) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _pulse.dispose();
    _exit.dispose();
    super.dispose();
  }

  double get _ms => _tl == null ? 0 : _t.value * _tl!.total;

  Future<void> _load() async {
    try {
      final service = WorldZoneService();
      final world = await service.getFullWorld();
      final regionId = world.userProgress.currentRegionId;
      if (regionId == null || regionId.isEmpty) throw StateError('no region');
      final region = await service.getRegionDetail(regionId);
      final main = region.nodes.where((n) => n.branchOf == null).toList()
        ..sort((a, b) => a.tier.compareTo(b.tier));
      var start =
          main.indexWhere((n) => n.id == world.userProgress.currentZoneId);
      if (start < 0) start = 0;
      final trail = main.skip(start).take(_visible).toList();
      final banked = world.userProgress.pendingDistanceKm;

      var reach = 0;
      var walked = 0.0;
      for (var i = 1; i < trail.length; i++) {
        final km = trail[i].distanceKm;
        if (walked + km > banked + 1e-6) break;
        walked += km;
        reach = i;
        final z = trail[i];
        if (z.isChest || z.isDungeon || z.isBoss || z.isCrossroads) break;
      }
      if (!mounted) return;
      final plan = _Plan(region, trail, banked, reach, walked);
      final tl = _Timeline.of(plan);
      setState(() {
        _plan = plan;
        _tl = tl;
      });
      _t.duration = Duration(milliseconds: tl.total.round());
      if (onboardingMotion(context)) {
        _t.forward(from: 0);
      } else {
        _arrived = tl.reach;
        _t.value = 1;
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t load the map.');
    }
  }

  void _onTick() {
    final tl = _tl, plan = _plan;
    if (tl == null || plan == null) return;
    final ms = _ms;
    while (_arrived < tl.reach && ms >= tl.arrive[_arrived + 1]) {
      _arrived++;
      final last = _arrived == tl.reach && plan.blocked;
      AppMotion.haptic(last ? AppHaptic.medium : AppHaptic.selection);
    }
  }

  /// Tapping the map while the trail fills jumps to the end.
  void _skip() {
    final tl = _tl;
    if (tl == null || !_t.isAnimating || _ms >= tl.ctaAt) return;
    _arrived = tl.reach;
    _t.value = 1;
  }

  Future<bool> _save() async {
    final ctrl = OnboardingScope.read(context);
    final plan = _plan;
    try {
      await ctrl.completeSetup();
      if (plan != null && plan.reachIndex > 0) {
        try {
          await WorldZoneService().setDestination(plan.target.id);
        } catch (_) {
          // The km stay banked; the player can pick a destination on the map.
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _enter() async {
    if (_saving) return;
    final ctrl = OnboardingScope.read(context);
    final motion = onboardingMotion(context);
    setState(() => _saving = true);
    if (motion) {
      _exit.animateTo(.5, duration: const Duration(milliseconds: 450));
    }
    final ok = await _save();
    if (!mounted) return;
    if (!ok) {
      _exit.animateBack(0, duration: const Duration(milliseconds: 300));
      setState(() => _saving = false);
      AppToast.error(context, 'Couldn\'t save your hero. Try again.');
      return;
    }
    if (motion) await _exit.animateTo(1);
    if (!mounted) return;
    final cls = ctrl.chosenClass;
    final devoted = ctrl.recommendation?.traitKey != null &&
        cls?.id == ctrl.recommendation?.recommendedClassId;
    PendingWelcome.set(
        'Welcome, ${devoted ? 'Devoted ' : ''}${cls?.name ?? 'hero'}. Your streak starts today.');
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: motion ? 450 : 0),
        pageBuilder: (_, __, ___) => MainShell(initialRingIds: ctrl.ringItems),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final avatar = avatarIconAsset(ctrl.avatarEmoji);
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(builder: (context, box) {
        final plan = _plan;
        final stage =
            _Stage(box.biggest, plan == null ? 1 : plan.trail.length);
        return AnimatedBuilder(
          animation: Listenable.merge([_t, _pulse, _exit]),
          builder: (context, _) {
            final ms = plan == null ? 0.0 : _ms;
            final tl = _tl;
            final cam = _camera(stage, tl, ms);
            final ex = _ease(_exit.value);
            final uiO = 1 - _cl(_exit.value * 2.5);
            final exitTarget = plan == null
                ? stage.focus
                : cam.project(
                    plan.reachIndex > 0
                        ? stage.points[math.min(plan.reachIndex, stage.count - 1)]
                        : (stage.count > 1 ? stage.points[1] : stage.points[0]),
                    stage.focus);
            final ctaO = plan == null
                ? (_error != null ? 1.0 : 0.0)
                : _out((ms - tl!.ctaAt) / 400);

            return Stack(
              children: [
                // Scene: zooms into the reached stop on exit.
                Positioned.fill(
                  child: Transform.scale(
                    scale: 1 + .8 * ex,
                    alignment: Alignment(
                      exitTarget.dx / stage.size.width * 2 - 1,
                      exitTarget.dy / stage.size.height * 2 - 1,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _skip,
                      child: _Scene(
                        stage: stage,
                        plan: plan,
                        tl: tl,
                        ms: ms,
                        cam: cam,
                        pulse: _pulse.value,
                        avatarAsset: avatar,
                      ),
                    ),
                  ),
                ),
                // Keep the header and panel readable while zoomed in.
                IgnorePointer(
                  child: Opacity(
                    opacity: _cl((cam.z - 1) / .5),
                    child: const Column(
                      children: [
                        _Scrim(height: 240, top: true),
                        Spacer(),
                        _Scrim(height: 260, top: false),
                      ],
                    ),
                  ),
                ),
                // UI
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _exit.value > 0,
                    child: Opacity(
                      opacity: uiO,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 20,
                            top: pad.top + 12,
                            child: Opacity(
                              opacity: plan == null ? 1 : _out((ms - 200) / 300),
                              child: OnboardingBackButton(onTap: ctrl.back),
                            ),
                          ),
                          Positioned(
                            left: 60,
                            right: 60,
                            top: pad.top + 21,
                            child: plan == null
                                ? const SizedBox.shrink()
                                : _ChapterHeader(plan: plan, tl: tl!, ms: ms),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: pad.bottom + 16,
                            child: Column(
                              children: [
                                if (plan != null)
                                  Builder(builder: (_) {
                                    final p = _out((ms - 1200) / 400);
                                    return Opacity(
                                      opacity: p,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1 - p)),
                                        child: _JourneyPanel(
                                            plan: plan, tl: tl!, ms: ms),
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 12),
                                Opacity(
                                  opacity: ctaO,
                                  child: Transform.translate(
                                    offset: Offset(0, 12 * (1 - ctaO)),
                                    child: _EnterButton(
                                      busy: _saving,
                                      pulse: _pulse.value,
                                      onPressed: ctaO > .5 ? _enter : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (plan == null)
                            Center(
                              child: _error != null
                                  ? Text(_error!,
                                      style: const TextStyle(
                                          color: AppColors.red, fontSize: 13))
                                  : const CircularProgressIndicator(
                                      color: AppColors.green),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Exit: fade to black.
                IgnorePointer(
                  child: Opacity(
                    opacity: _cl((_exit.value - .5) / .3),
                    child: Container(
                      color: AppColors.background,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: _cl((_exit.value - .7) / .25),
                        child: const Text(
                          'ENTERING THE WORLD',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  /// Wide shot during the intro, then centre and zoom on each stop as the
  /// fill reaches it, hold, and pull back to the whole trail at the end.
  _Cam _camera(_Stage stage, _Timeline? tl, double ms) {
    final wide = _Cam(stage.focus, 1);
    final plan = _plan;
    if (tl == null || plan == null) return wide;
    _Cam at(int i) =>
        i == 0 ? wide : _Cam(stage.points[i], stage.zoomFor(i));

    if (tl.reach == 0) {
      if (stage.count < 2) return wide;
      return _Cam.mix(
          wide, _Cam(stage.points[1], 1.3), _ease((ms - 1500) / 900));
    }
    if (ms >= tl.pullAt) {
      return _Cam.mix(at(tl.reach), wide, _ease((ms - tl.pullAt) / 700));
    }
    for (var i = tl.reach; i >= 1; i--) {
      if (ms >= tl.arrive[i]) return at(i);
      if (ms >= tl.start[i]) {
        return _Cam.mix(at(i - 1), at(i),
            _ease((ms - tl.start[i]) / (tl.arrive[i] - tl.start[i])));
      }
    }
    return wide;
  }
}

// ── Scene ────────────────────────────────────────────────────────────────────

class _Scene extends StatelessWidget {
  final _Stage stage;
  final _Plan? plan;
  final _Timeline? tl;
  final double ms;
  final _Cam cam;
  final double pulse;
  final String? avatarAsset;

  const _Scene({
    required this.stage,
    required this.plan,
    required this.tl,
    required this.ms,
    required this.cam,
    required this.pulse,
    required this.avatarAsset,
  });

  @override
  Widget build(BuildContext context) {
    final plan = this.plan, tl = this.tl;
    final focus = stage.focus;

    // Background drifts at a third of the camera's speed (parallax) and
    // settles from a slight zoom during the intro.
    final intro = plan == null ? 1.12 : 1.12 - .12 * _out(ms / 600);
    final bc = focus + (cam.c - focus) * .35;
    final bz = (1 + (cam.z - 1) * .35) * intro;
    final bg = _Cam(bc, bz).matrix(focus);

    final progress = tl?.progress(ms) ?? 0;
    final fillFraction =
        tl == null || tl.reach == 0 ? 0.0 : progress / tl.reach;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: Transform(
            transform: bg,
            child: OverflowBox(
              maxWidth: stage.size.width + 120,
              maxHeight: stage.size.height + 120,
              child: RepaintBoundary(
                child: Opacity(
                  opacity: plan == null ? 1 : _out(ms / 500),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Color(0x4D040810), BlendMode.srcATop),
                    child: Image.asset(AppIcons.homeSceneBg,
                        fit: BoxFit.cover,
                        width: stage.size.width + 120,
                        height: stage.size.height + 120),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Transform(
            transform: cam.matrix(focus),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Vignette + fog that lifts as the km fill the trail.
                const Positioned(
                  left: -60,
                  right: -60,
                  top: -60,
                  bottom: -60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xD9040810),
                          Color(0x26040810),
                          Color(0x40040810),
                          Color(0xF7040810),
                        ],
                        stops: [0, .32, .6, .82],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -60,
                  right: -60,
                  top: -60,
                  bottom: -60,
                  child: ColoredBox(
                    color: const Color(0xFF040810)
                        .withValues(alpha: .5 * (1 - .6 * fillFraction)),
                  ),
                ),
                if (plan != null && tl != null) ...[
                  for (var i = 1; i < stage.count; i++)
                    if (tl.reached(i, ms))
                      _GroundGlow(
                        at: stage.points[i],
                        size: stage.nodeSize(i) * 3,
                        color: _stopColor(plan, i),
                        opacity: tl.arrival(i, ms),
                      ),
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _RoadPainter(
                          stage: stage,
                          reveal: _ease((ms - 700) / 800),
                          fill: stage.lengthAt(progress),
                          head: tl.moving(ms),
                          preview: tl.reach == 0 && stage.count > 1
                              ? _out((ms - 1500) / 400)
                              : 0,
                          march: pulse,
                        ),
                      ),
                    ),
                  ),
                  // Far stops first so nearer ones draw on top.
                  for (var i = stage.count - 1; i >= 1; i--)
                    ..._stop(context, plan, tl, i),
                  _StartZone(stage: stage, plan: plan, ms: ms),
                  _traveller(plan, tl, progress),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The hero's avatar badge. It sits on the corner of the stop the hero is
  /// at, rides the tip of the fill between stops, and lands on the stop the
  /// imported km reach — so the hero only ever appears once on the map.
  Widget _traveller(_Plan plan, _Timeline tl, double progress) {
    final i = progress.floor().clamp(0, stage.count - 1);
    final f = progress - i;
    final j = math.min(i + 1, stage.count - 1);
    final tip = stage.count < 2
        ? stage.points[0]
        : stage.metric
                .getTangentForOffset(stage.lengthAt(progress))
                ?.position ??
            stage.points[i];
    var node = stage.nodeSize(i) + (stage.nodeSize(j) - stage.nodeSize(i)) * f;
    if (i == tl.reach && plan.blocked) node *= 1 + .12 * _back(tl.arrival(i, ms));
    // 1 while resting on a stop, 0 halfway between two.
    final rest = 1 - math.sin(math.pi * f);
    final c = tip + Offset(node * .42, node * .42) * rest;
    final size = 34 * stage.s * (.75 + .25 * node / stage.nodeSize(0));
    final pop = _cl((ms - 450) / 450);
    final moving = tl.moving(ms);
    return Positioned(
      left: c.dx - size / 2,
      top: c.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Opacity(
          opacity: _out(pop * 1.5),
          child: Transform.scale(
            scale: .4 + .6 * _back(pop),
            child: _AvatarDisc(asset: avatarAsset, ring: 2.5, glow: moving),
          ),
        ),
      ),
    );
  }

  List<Widget> _stop(BuildContext context, _Plan plan, _Timeline tl, int i) {
    final node = plan.trail[i];
    final p = stage.points[i];
    final size = stage.nodeSize(i);
    final frac = stage.length == 0 ? 0 : stage.stops[i] / stage.length;
    final popT = 700 + frac * 800;
    final pop = _cl((ms - popT) / 350);
    final reached = tl.reached(i, ms);
    final a = tl.arrival(i, ms);
    final last = i == tl.reach;
    final blocker = last && plan.blocked;
    final next = tl.reach == 0 && i == 1;
    final color = _stopColor(plan, i);

    final Color ring;
    final double ringW;
    List<BoxShadow>? glow;
    double scale;
    if (reached) {
      ring = color;
      ringW = 3;
      glow = [
        BoxShadow(
            color: color.withValues(alpha: .6),
            blurRadius: (10 + (blocker ? 30 : 24) * a) * stage.s)
      ];
      scale = blocker
          ? 1 + .12 * _back(a) + .03 * math.sin(pulse * 2 * math.pi) * a
          : 1 + .25 * (1 - _back(a));
    } else {
      ring = next
          ? AppColors.blue
          : node.isChest
              ? AppColors.orange.withValues(alpha: .45)
              : node.isDungeon
                  ? AppColors.purple.withValues(alpha: .6)
                  : AppColors.border;
      ringW = next ? 2 : 1.5;
      glow = next
          ? [BoxShadow(color: AppColors.blue.withValues(alpha: .3), blurRadius: 20)]
          : null;
      scale = 1;
    }
    final opacity = (reached ? 1.0 : stage.depthOpacity(i)) * _out(pop);
    final entry = .6 + .4 * _back(pop);

    final widgets = <Widget>[
      // Repeating ring: pulses out of the stop the hero has to deal with next.
      if ((blocker && reached) || (next && ms > 1500))
        Positioned(
          left: p.dx - size / 2,
          top: p.dy - size / 2,
          width: size,
          height: size,
          child: IgnorePointer(
            child: Transform.scale(
              scale: (blocker ? 1.12 : 1) * (1 + (blocker ? 1 : .6) * pulse),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: (blocker ? color : AppColors.blue)
                          .withValues(alpha: .8 * (1 - pulse)),
                      width: 2),
                ),
              ),
            ),
          ),
        ),
      Positioned(
        left: p.dx - size / 2,
        top: p.dy - size / 2,
        width: size,
        height: size,
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: entry * scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xE0040810),
                border: Border.all(color: ring, width: ringW),
                boxShadow: glow,
              ),
              alignment: Alignment.center,
              child: MapIconOrEmoji(
                asset: _stopIcon(plan, i),
                emoji: node.emoji,
                size: size * (node.isChest ? .66 : .78),
                emojiSize: size * .45,
                visualScale: node.isChest ? 1 : 1.25,
                opacity: reached || next || i <= 2 ? 1 : .75,
              ),
            ),
          ),
        ),
      ),
    ];

    // Labels on the three nearest stops.
    if (i <= 3) {
      widgets.add(_StopLabel(
        stage: stage,
        at: p,
        size: size * (reached && blocker ? 1.12 : 1),
        node: node,
        tag: next ? 'NEXT' : (reached && !last ? 'REACHED' : null),
        tagColor: next ? AppColors.blue : AppColors.green,
        sub: _sub(plan, i, reached),
        subColor: reached ? color : AppColors.textSecondary,
        opacity: _out((ms - popT - 100) / 300) * (i == 3 ? .8 : 1),
        small: i == 3,
      ));
    }

    // "+N XP" floats up from each regular stop as it's reached.
    if (reached && !blocker && node.xpReward > 0) {
      final f = _cl((ms - tl.arrive[i] - 50) / 1100);
      if (f > 0 && f < 1) {
        widgets.add(Positioned(
          left: p.dx - 40 * stage.s,
          width: 80 * stage.s,
          top: p.dy - size * .9 - 50 * stage.s * f,
          child: Opacity(
            opacity: 1 - f * f,
            child: Text(
              '+${node.xpReward} XP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * stage.s,
                fontWeight: FontWeight.w900,
                color: AppColors.orange,
                shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  String _sub(_Plan plan, int i, bool reached) {
    final node = plan.trail[i];
    if (reached && i == plan.reachIndex && plan.blocked) {
      if (node.isChest) {
        final xp = node.chestRewardXp ?? node.xpReward;
        return xp > 0 ? 'Chest waiting · +$xp XP' : 'Chest waiting';
      }
      if (node.isDungeon) {
        final floors = node.dungeonFloorsTotal;
        return floors != null ? 'Dungeon · $floors trials' : 'Dungeon';
      }
      if (node.isBoss) return 'Boss';
      return 'Choose a path';
    }
    if (reached) return node.xpReward > 0 ? '+${node.xpReward} XP' : 'Reached';
    final km = '${node.distanceKm.toStringAsFixed(1)} km';
    if (node.isChest) return 'Chest · $km';
    if (node.isDungeon) return 'Dungeon · $km';
    return node.xpReward > 0 && i == 1 ? '$km · +${node.xpReward} XP' : km;
  }
}

/// Zone art for the trail. Chests, bosses, dungeons and forks keep their
/// map icons; regular zones pick art from their name so the stops don't all
/// share the region's tree, and neighbours never repeat the same icon.
String? _stopIcon(_Plan plan, int i) {
  final node = plan.trail[i];
  if (node.isChest || node.isBoss || node.isDungeon || node.isCrossroads) {
    return zoneNodeIconAsset(node,
        regionTheme: plan.region.theme, regionName: plan.region.name);
  }
  const byKeyword = <String, List<String>>{
    AppIcons.zoneAshfieldPlains: ['camp', 'plain', 'field', 'meadow', 'valley', 'road', 'glade'],
    AppIcons.zoneFinalApproach: ['forge', 'gate', 'approach', 'keep', 'fort', 'tower', 'hall', 'temple'],
    AppIcons.zoneIronPeaks: ['peak', 'mountain', 'ridge', 'cliff', 'summit', 'pass', 'rock'],
    AppIcons.zoneFrostboundPeaks: ['frost', 'ice', 'snow', 'glacier', 'tundra'],
    AppIcons.zoneCoralCoast: ['coast', 'reef', 'shore', 'tide', 'current', 'bay'],
    AppIcons.zoneDesertOfTrials: ['desert', 'dune', 'sand', 'mirage'],
    AppIcons.zoneThornwoodForest: ['pine', 'wood', 'forest', 'grove', 'tree', 'thorn'],
  };
  final name = node.name.toLowerCase();
  String? icon;
  for (final e in byKeyword.entries) {
    if (e.value.any(name.contains)) {
      icon = e.key;
      break;
    }
  }
  icon ??= zoneNodeIconAsset(node,
      regionTheme: plan.region.theme, regionName: plan.region.name);
  final previous = i > 0 ? _stopIcon(plan, i - 1) : null;
  if (icon != previous) return icon;
  const pool = [
    AppIcons.zoneThornwoodForest,
    AppIcons.zoneAshfieldPlains,
    AppIcons.zoneFinalApproach,
    AppIcons.zoneIronPeaks,
  ];
  return pool.firstWhere((p) => p != previous, orElse: () => icon!);
}

Color _stopColor(_Plan plan, int i) {
  if (i != plan.reachIndex || !plan.blocked) return AppColors.green;
  final n = plan.trail[i];
  if (n.isChest) return AppColors.orange;
  if (n.isDungeon) return AppColors.purple;
  if (n.isBoss) return AppColors.red;
  return AppColors.blue;
}

class _GroundGlow extends StatelessWidget {
  final Offset at;
  final double size;
  final Color color;
  final double opacity;
  const _GroundGlow(
      {required this.at,
      required this.size,
      required this.color,
      required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size * .35,
      width: size,
      height: size * .7,
      child: IgnorePointer(
        child: Opacity(
          opacity: _out(opacity),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [
                color.withValues(alpha: .3),
                color.withValues(alpha: 0),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _StopLabel extends StatelessWidget {
  final _Stage stage;
  final Offset at;
  final double size;
  final ZoneNode node;
  final String? tag;
  final Color tagColor;
  final String sub;
  final Color subColor;
  final double opacity;
  final bool small;

  const _StopLabel({
    required this.stage,
    required this.at,
    required this.size,
    required this.node,
    required this.tag,
    required this.tagColor,
    required this.sub,
    required this.subColor,
    required this.opacity,
    required this.small,
  });

  @override
  Widget build(BuildContext context) {
    final s = stage.s;
    final right = at.dx > stage.size.width / 2;
    final gap = size / 2 + 8 * s;
    const shadow = [Shadow(color: Colors.black, blurRadius: 6)];
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          right ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (tag != null)
          Text(tag!,
              style: TextStyle(
                  fontSize: 9 * s,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: tagColor,
                  shadows: shadow)),
        Text(node.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: (small ? 10 : 12.5) * s,
                fontWeight: FontWeight.w800,
                color: small ? const Color(0xFFB9C1CA) : AppColors.textPrimary,
                shadows: shadow)),
        if (!small)
          Text(sub,
              style: TextStyle(
                  fontSize: 10.5 * s,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                  shadows: shadow)),
      ],
    );
    return Positioned(
      left: right ? at.dx + gap : null,
      right: right ? null : stage.size.width - (at.dx - gap),
      top: at.dy - (tag != null ? 22 : 16) * s,
      width: 130 * s,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Align(
            alignment: right ? Alignment.centerLeft : Alignment.centerRight,
            child: column,
          ),
        ),
      ),
    );
  }
}

/// The zone the hero starts in: a regular zone node at the near end of the
/// trail, popping in with a ring during the intro.
class _StartZone extends StatelessWidget {
  final _Stage stage;
  final _Plan plan;
  final double ms;

  const _StartZone({required this.stage, required this.plan, required this.ms});

  @override
  Widget build(BuildContext context) {
    final c = stage.points[0];
    final size = stage.nodeSize(0);
    final node = plan.trail.first;
    final p = _cl((ms - 300) / 500);
    final shock = _cl((ms - 550) / 650);
    final o = _out(p * 1.4);
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: c.dx - 70 * stage.s,
              top: c.dy + size * .35,
              width: 140 * stage.s,
              height: 30 * stage.s,
              child: Opacity(
                opacity: o,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [
                      AppColors.blue.withValues(alpha: .4),
                      AppColors.blue.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ),
            if (shock > 0 && shock < 1)
              Positioned(
                left: c.dx - size / 2,
                top: c.dy - size / 2,
                width: size,
                height: size,
                child: Transform.scale(
                  scale: 1 + 1.2 * _out(shock),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.blue
                              .withValues(alpha: .8 * (1 - shock)),
                          width: 2),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: c.dx - size / 2,
              top: c.dy - size / 2,
              width: size,
              height: size,
              child: Opacity(
                opacity: o,
                child: Transform.scale(
                  scale: .5 + .5 * _back(p),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xE0040810),
                      border: Border.all(color: AppColors.blue, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.blue.withValues(alpha: .35),
                            blurRadius: 24),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: MapIconOrEmoji(
                      asset: _stopIcon(plan, 0),
                      emoji: node.emoji,
                      size: size * .78,
                      emojiSize: size * .45,
                      visualScale: 1.25,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: c.dy + size / 2 + 12 * stage.s,
              child: Opacity(
                opacity: o,
                child: Text(
                  node.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11 * stage.s,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: const Color(0xFFB9C1CA),
                    shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarDisc extends StatelessWidget {
  final String? asset;
  final double ring;
  final bool glow;
  const _AvatarDisc({required this.asset, required this.ring, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = box.maxWidth;
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0B1017),
          border: Border.all(color: AppColors.blue, width: ring),
          boxShadow: glow
              ? [
                  BoxShadow(
                      color: AppColors.blue.withValues(alpha: .5),
                      blurRadius: 36),
                  BoxShadow(
                      color: AppColors.blue.withValues(alpha: .12),
                      spreadRadius: 8),
                ]
              : null,
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        child: asset != null
            // The art fills the disc; skip AppIconImage's default 1.6× bleed.
            ? AppIconImage(asset!, size: size * .8, visualScale: 1)
            : Icon(Icons.person, size: size * .5, color: AppColors.blue),
      );
    });
  }
}

class _Scrim extends StatelessWidget {
  final double height;
  final bool top;
  const _Scrim({required this.height, required this.top});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: const [Color(0xE6040810), Color(0x00040810)],
          ),
        ),
      ),
    );
  }
}

// ── Road ─────────────────────────────────────────────────────────────────────

class _RoadPainter extends CustomPainter {
  final _Stage stage;
  final double reveal; // 0→1 intro draw-in of the whole trail
  final double fill; // arc length filled by imported km
  final bool head; // glowing tip while the fill is moving
  final double preview; // 0 km: dashes marching toward the next stop
  final double march;

  _RoadPainter({
    required this.stage,
    required this.reveal,
    required this.fill,
    required this.head,
    required this.preview,
    required this.march,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stage.count < 2) return;
    final m = stage.metric;
    final s = stage.s;
    final shown = stage.length * reveal;
    if (shown > 0) {
      canvas.drawPath(
        m.extractPath(0, shown),
        Paint()
          ..color = AppColors.textPrimary.withValues(alpha: .07)
          ..strokeWidth = 16 * s
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      final dot = Paint()
        ..color = AppColors.textPrimary.withValues(alpha: .35)
        ..strokeWidth = 3 * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (double d = 0; d < shown; d += 10 * s) {
        canvas.drawPath(m.extractPath(d, d + .5), dot);
      }
    }

    if (preview > 0) {
      final dash = Paint()
        ..color = AppColors.blue.withValues(alpha: .9 * preview)
        ..strokeWidth = 4 * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final period = 17 * s, end = stage.stops[1];
      for (double d = -period + march * period; d < end; d += period) {
        final a = d.clamp(0.0, end), b = (d + 10 * s).clamp(0.0, end);
        if (b > a) canvas.drawPath(m.extractPath(a, b), dash);
      }
    }

    if (fill > 0) {
      final done = m.extractPath(0, fill);
      canvas.drawPath(
        done,
        Paint()
          ..color = AppColors.green.withValues(alpha: .25)
          ..strokeWidth = 12 * s
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        done,
        Paint()
          ..color = AppColors.green
          ..strokeWidth = 5 * s
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      if (head) {
        final tip = m.getTangentForOffset(fill)?.position;
        if (tip != null) {
          canvas.drawCircle(
            tip,
            16 * s,
            Paint()
              ..shader = ui.Gradient.radial(tip, 16 * s, [
                Colors.white,
                const Color(0xFF7EE787),
                AppColors.green.withValues(alpha: 0),
              ], [0, .3, 1]),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter o) =>
      o.reveal != reveal ||
      o.fill != fill ||
      o.head != head ||
      o.preview != preview ||
      (preview > 0 && o.march != march) ||
      o.stage != stage;
}

// ── Enter button ─────────────────────────────────────────────────────────────

/// Gilded call to action that matches the chapter header: gold rim, warm dark
/// face, serif label between two diamonds, a breathing glow and a light sweep.
class _EnterButton extends StatelessWidget {
  static const _gold = Color(0xFFF5A623);
  static const _goldLight = Color(0xFFFFD98A);

  final bool busy;
  final double pulse;
  final VoidCallback? onPressed;

  const _EnterButton(
      {required this.busy, required this.pulse, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final breathe = .5 + .5 * math.sin(pulse * 2 * math.pi);
    // One sweep across the face early in each pulse cycle.
    final sweep = _cl(pulse / .45);
    Widget diamond() => Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _gold,
              boxShadow: [
                BoxShadow(color: _gold.withValues(alpha: .6), blurRadius: 6)
              ],
            ),
          ),
        );

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Enter the world',
      child: AppPressable(
        onTap: enabled ? onPressed : null,
        haptic: AppHaptic.medium,
        pressedScale: .97,
        child: Container(
          height: 58,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_goldLight, _gold, Color(0xFF9A6312)],
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: .16 + .14 * breathe),
                blurRadius: 18 + 10 * breathe,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.5),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A2214), Color(0xFF15110A)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Thin highlight along the top edge.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 1,
                    child: ColoredBox(color: _goldLight.withValues(alpha: .35)),
                  ),
                  if (enabled && sweep > 0 && sweep < 1)
                    Positioned.fill(
                      child: FractionalTranslation(
                        translation: Offset(-1.1 + 2.2 * sweep, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              _goldLight.withValues(alpha: 0),
                              _goldLight.withValues(alpha: .22),
                              _goldLight.withValues(alpha: 0),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  if (busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: _goldLight),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        diamond(),
                        const SizedBox(width: 14),
                        const Text(
                          'ENTER THE WORLD',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: _goldLight,
                            shadows: [
                              Shadow(color: Color(0x99F5A623), blurRadius: 10)
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        diamond(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header & panel ───────────────────────────────────────────────────────────

class _ChapterHeader extends StatelessWidget {
  final _Plan plan;
  final _Timeline tl;
  final double ms;
  const _ChapterHeader({required this.plan, required this.tl, required this.ms});

  static String _roman(int n) {
    const r = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
    return n >= 1 && n <= r.length ? r[n - 1] : '$n';
  }

  @override
  Widget build(BuildContext context) {
    final label = _out((ms - 200) / 300);
    final rule = 28 * _out((ms - 200) / 400);
    final title = _out((ms - 350) / 600);
    final spacing = 5 * (1 - _out((ms - 350) / 700));
    final chip = _out((ms - 900) / 300);
    final km = plan.kmAt(tl.progress(ms));
    final done = tl.reach == 0 || ms >= tl.arrive[tl.reach];
    final ruleLine = Container(
        width: rule, height: 1, color: AppColors.orange.withValues(alpha: .6));

    return Column(
      children: [
        SizedBox(
          height: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ruleLine,
              const SizedBox(width: 10),
              Opacity(
                opacity: label,
                child: Text(
                  'CHAPTER ${_roman(plan.region.chapterIndex)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: AppColors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ruleLine,
            ],
          ),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: title,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - title)),
            child: Text(
              plan.region.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: spacing,
                color: AppColors.textPrimary,
                shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 18)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: chip,
          child: plan.banked > 0
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.green.withValues(alpha: .35)),
                  ),
                  child: Text(
                    done
                        ? '${plan.banked.toStringAsFixed(1)} km carried in from your workouts'
                        : '+${km.toStringAsFixed(1)} km from your workouts',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                )
              : Text(
                  plan.region.lore,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFFB9C1CA),
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
        ),
      ],
    );
  }
}

class _JourneyPanel extends StatelessWidget {
  final _Plan plan;
  final _Timeline tl;
  final double ms;
  const _JourneyPanel({required this.plan, required this.tl, required this.ms});

  @override
  Widget build(BuildContext context) {
    final progress = tl.progress(ms);
    final legs = plan.trail.length - 1;
    final filling = tl.reach > 0 && ms < tl.arrive[tl.reach] + 400;
    final km = plan.kmAt(progress);

    String lead, accent = '', trailing = '';
    var accentColor = AppColors.blue, trailingColor = AppColors.orange;
    String caption;

    if (filling) {
      lead = 'Your imported km fill the trail…';
      trailing =
          '${km.toStringAsFixed(1)} / ${plan.walkedKm.toStringAsFixed(1)} km';
      trailingColor = AppColors.green;
      caption = 'Every km you logged lights up the road.';
    } else if (tl.reach > 0) {
      final t = plan.target;
      final left = plan.left;
      final banked = left > .05 ? ' · ${left.toStringAsFixed(1)} km banked' : '';
      caption =
          '${plan.walkedKm.toStringAsFixed(1)} km walked · ${tl.reach} of $legs stops$banked';
      if (plan.blocked) {
        lead = 'Stopped at ${t.name}. ';
        accentColor = _stopColor(plan, tl.reach);
        if (t.isChest) {
          accent = 'Open the chest.';
          final xp = t.chestRewardXp ?? t.xpReward;
          if (xp > 0) trailing = '+$xp XP';
        } else if (t.isDungeon) {
          accent = 'Clear its trials.';
        } else if (t.isBoss) {
          accent = 'Face the boss.';
        } else {
          accent = 'Choose your path.';
        }
      } else if (plan.next != null) {
        final away =
            (plan.next!.distanceKm - left).clamp(0.0, double.infinity);
        lead = 'Next stop: ';
        accent = plan.next!.name;
        trailing = '${away.toStringAsFixed(1)} km';
        trailingColor = AppColors.textSecondary;
      } else {
        lead = 'You reached ';
        accent = t.name;
        accentColor = AppColors.green;
      }
    } else if (plan.next != null) {
      final next = plan.next!;
      lead = 'Your first steps lead to ';
      accent = next.name;
      if (next.xpReward > 0) trailing = '+${next.xpReward} XP';
      caption = plan.banked <= 0
          ? '0.0 of ${next.distanceKm.toStringAsFixed(1)} km · log a run, ride or walk to set off'
          : '${plan.banked.toStringAsFixed(1)} of ${next.distanceKm.toStringAsFixed(1)} km banked · about 1 run to go';
    } else {
      lead = 'You\'re at ${plan.target.name}';
      caption = 'Log a run, ride or walk to start moving.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: lead),
                    if (accent.isNotEmpty)
                      TextSpan(
                          text: accent, style: TextStyle(color: accentColor)),
                  ]),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: trailingColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
          if (legs > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var l = 0; l < legs; l++) ...[
                  if (l > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _cl(progress - l),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tl.reached(l + 1, ms)
                                ? _stopColor(plan, l + 1)
                                : AppColors.green,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            caption,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}
