import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/boss/replay/home_boss_replay.dart';
import '../../../features/boss/providers/boss_provider.dart';
import '../../../features/home/providers/world_progress_provider.dart';
import '../../constants/app_colors.dart';
import '../../../features/map/journey/journey_state.dart';
import '../../../features/unlocks/models/unlock_catalog.dart';
import '../../../features/unlocks/providers/unlocks_provider.dart';
import '../../../features/unlocks/tour/tour_target.dart';
import '../../../features/unlocks/tour/tours/unlock_tours.dart';
import '../../../features/unlocks/widgets/unlock_badges.dart';
import '../../motion/app_motion.dart';
import '../../motion/reward_fx.dart';
import '../../widgets/app_icon_image.dart';
import '../shell_anchors.dart';

const kMapOrbSize = 78.0;

/// The raised Map button in the middle of the tab bar. Its ring, colour,
/// icon and label mirror the journey card; a pulsing dot means "act now".
class MapOrbButton extends ConsumerStatefulWidget {
  final bool open;
  final VoidCallback onTap;
  const MapOrbButton({super.key, required this.open, required this.onTap});

  @override
  ConsumerState<MapOrbButton> createState() => _MapOrbButtonState();
}

class _MapOrbButtonState extends ConsumerState<MapOrbButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: 1,
  );
  late final AnimationController _tremble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  JourneyKind? _lastKind;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    bossOrbFx.addListener(_onFx);
  }

  void _onFx() {
    if (!mounted) return;
    if (bossOrbFx.value == BossOrbFxMode.charge &&
        AppMotion.allowsDecorativeMotion(context)) {
      _tremble.repeat();
    } else {
      _tremble.stop();
      _tremble.value = 0;
    }
    if (bossOrbFx.value == BossOrbFxMode.victory) _pop.forward(from: 0);
    setState(() {});
  }

  /// A recovery label ticks every second while it is on screen.
  void _syncCountdown(DateTime? to) {
    if (to == null) {
      _countdown?.cancel();
      _countdown = null;
    } else {
      _countdown ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    bossOrbFx.removeListener(_onFx);
    _countdown?.cancel();
    _pulse.dispose();
    _pop.dispose();
    _tremble.dispose();
    super.dispose();
  }

  void _syncPulse(bool alert) {
    final want = alert && AppMotion.allowsDecorativeMotion(context);
    if (want && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!want && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(journeyOrbStateProvider);
    final world = ref.watch(worldProgressProvider).valueOrNull;
    final activeBoss = ref
        .watch(bossListProvider)
        .valueOrNull
        ?.where((boss) => boss.isActive)
        .firstOrNull;
    final secondZone =
        activeBoss != null && hasSeparateMapAction(activeBoss, world)
            ? pickPortalZone(world!)
            : null;
    final routeFocused = ref.watch(journeyFocusProvider) == JourneyFocus.route;
    final fx = bossOrbFx.value;
    final victory = fx == BossOrbFxMode.victory;
    final charging = fx == BossOrbFxMode.charge;
    _syncCountdown(live.countdownTo);
    final countdown = live.countdownTo?.difference(DateTime.now());
    final s = victory
        ? JourneyOrbState(
            kind: live.kind,
            color: const Color(0xFFF5A623),
            ring: JourneyRing.progress,
            progress: 0,
            iconAsset: live.iconAsset,
            label: 'Victory',
            secondaryProgress: live.secondaryProgress,
            secondaryColor: live.secondaryColor,
            semantics: 'Boss defeated',
          )
        : countdown != null
            ? JourneyOrbState(
                kind: live.kind,
                color: live.color,
                ring: live.ring,
                progress: live.progress,
                iconAsset: live.iconAsset,
                label: formatCountdown(countdown),
                secondaryProgress: live.secondaryProgress,
                secondaryColor: live.secondaryColor,
                countdownTo: live.countdownTo,
                semantics: live.semantics,
              )
            : live;
    final locked = !ref.watch(isUnlockedProvider(UnlockKeys.map));
    final fresh = ref.watch(isFreshUnlockProvider(UnlockKeys.map));
    if (_lastKind != null &&
        _lastKind != s.kind &&
        AppMotion.allowsDecorativeMotion(context)) {
      // New situation on the journey: the icon pops and a ring goes out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pop.forward(from: 0);
        final c = ShellAnchors.mapOrb.center;
        if (c != null) RewardFx.ring(context, c, s.color, maxRadius: 56);
      });
    }
    _lastKind = s.kind;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPulse(s.alert && !widget.open);
    });

    final glow = charging
        ? const Color(0xFFF5A623).withValues(alpha: .7)
        : s.color.withValues(alpha: .32);
    final bg = HSLColor.fromColor(s.color);
    final bgTop =
        bg.withLightness(.16).withSaturation(bg.saturation * .6).toColor();

    return Semantics(
      button: true,
      label: locked
          ? 'Map, locked'
          : 'Map. ${s.semantics}${secondZone == null ? '' : routeFocused ? '. Also boss raid' : '. Also ${secondZone.name}'}',
      child: FxAnchorTarget(
        anchor: ShellAnchors.mapOrb,
        child: TourTarget(
          id: TourIds.mapOrb,
          child: AppPressable(
            haptic: AppHaptic.light,
            pressedScale: .94,
            onTap: widget.onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _tremble,
                  builder: (_, child) => _tremble.isAnimating
                      ? Transform.translate(
                          offset: Offset(
                              math.sin(_tremble.value * math.pi * 2) * 1.5,
                              math.cos(_tremble.value * math.pi * 2) * 1.2),
                          child: child)
                      : child!,
                  child: ColorFiltered(
                    colorFilter: locked
                        ? const ColorFilter.matrix([
                            .15, .3, .05, 0, 0, //
                            .15, .3, .05, 0, 0,
                            .15, .3, .05, 0, 0,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst),
                    child: SizedBox(
                      width: kMapOrbSize,
                      height: kMapOrbSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // "Act now" pulse.
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, __) {
                              if (!_pulse.isAnimating) {
                                return const SizedBox.shrink();
                              }
                              final t = _pulse.value;
                              return Transform.scale(
                                scale: .92 + .38 * t,
                                child: Container(
                                  width: kMapOrbSize,
                                  height: kMapOrbSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: s.color
                                          .withValues(alpha: .8 * (1 - t)),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedContainer(
                            duration: AppMotion.duration(
                                context, AppMotionTokens.micro),
                            width: kMapOrbSize,
                            height: kMapOrbSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-.24, -.4),
                                radius: .9,
                                colors: [bgTop, const Color(0xFF090D16)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: glow,
                                    blurRadius: 22,
                                    offset: const Offset(0, 6)),
                                const BoxShadow(
                                    color: Color(0xFF040810), spreadRadius: 5),
                                if (widget.open)
                                  BoxShadow(color: s.color, spreadRadius: 7),
                                if (widget.open)
                                  const BoxShadow(
                                      color: Color(0xFF040810),
                                      spreadRadius: 5),
                              ],
                            ),
                          ),
                          if (charging)
                            Positioned(
                              left: -14,
                              top: -14,
                              right: -14,
                              bottom: -14,
                              child: AnimatedBuilder(
                                animation: _tremble,
                                builder: (_, __) => CustomPaint(
                                  painter: _ChargeRingPainter(_tremble.value),
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: s.secondaryProgress != null
                                  // A fight: your HP on the left half, the
                                  // foe's on the right, in today's ring.
                                  ? _TrailedDuelRing(
                                      you: s.secondaryProgress!,
                                      youColor:
                                          s.secondaryColor ?? AppColors.green,
                                      foe: s.progress,
                                      foeColor: s.color,
                                    )
                                  : s.ring == JourneyRing.progress
                                      ? _TrailedRing(
                                          ring: s.ring,
                                          color: s.color,
                                          progress: s.progress,
                                        )
                                      : TweenAnimationBuilder<double>(
                                          tween: Tween(end: s.progress),
                                          duration: AppMotion.duration(
                                              context,
                                              const Duration(
                                                  milliseconds: 900)),
                                          curve: Curves.easeOutCubic,
                                          builder: (_, v, __) => CustomPaint(
                                            painter: JourneyRingPainter(
                                              ring: s.ring,
                                              color: s.color,
                                              progress: v,
                                              segments: s.segments,
                                              segmentsDone: s.segmentsDone,
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                          ScaleTransition(
                            scale: CurvedAnimation(
                                parent: _pop, curve: Curves.easeOutBack),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: s.iconAsset != null
                                      ? Center(
                                          child: AppIconImage(s.iconAsset!,
                                              // The Wayfarer chest art fills
                                              // its frame; keep it a touch
                                              // smaller than other icons.
                                              size:
                                                  s.kind == JourneyKind.chest ||
                                                          s.kind ==
                                                              JourneyKind
                                                                  .chestOpened
                                                      ? 25
                                                      : 30))
                                      : Icon(s.icon,
                                          size: 24, color: Colors.white),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  s.label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: _labelColor(s.color),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                    shadows: const [
                                      Shadow(
                                          color: Color(0xCC000000),
                                          blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (s.alert && !widget.open && !locked)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: s.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF040810), width: 2),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          if (secondZone != null && !locked)
                            Positioned(
                              right: -2,
                              bottom: 1,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: routeFocused
                                      ? AppColors.red
                                      : AppColors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF040810),
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  routeFocused
                                      ? Icons.sports_martial_arts_rounded
                                      : secondZone.type == 'crossroads'
                                          ? Icons.alt_route_rounded
                                          : secondZone.type == 'chest'
                                              ? Icons.inventory_2_rounded
                                              : Icons.map_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (locked)
                  const Positioned(top: -2, right: -2, child: LockBadge()),
                if (fresh && !locked)
                  const Positioned(top: -6, right: -12, child: NewPill()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _labelColor(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(math.max(hsl.lightness, .72)).toColor();
  }
}

/// Draws the Map button's ring: progress arc, dashed circle, two-path split
/// or dungeon floor segments.
class JourneyRingPainter extends CustomPainter {
  final JourneyRing ring;
  final Color color;
  final double progress;
  final int segments;
  final int segmentsDone;
  final double stroke;

  /// False for the pale "trail" arc drawn under the live one.
  final bool showTrack;

  JourneyRingPainter({
    required this.ring,
    required this.color,
    required this.progress,
    this.segments = 0,
    this.segmentsDone = 0,
    this.stroke = 4.5,
    this.showTrack = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: .2);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    const start = -math.pi / 2;
    const full = 2 * math.pi;

    switch (ring) {
      case JourneyRing.progress:
        if (showTrack) canvas.drawArc(rect, 0, full, false, track);
        final p = progress.clamp(0.0, 1.0);
        if (p > 0) canvas.drawArc(rect, start, full * p, false, fill);
      case JourneyRing.dashed:
        const n = 14;
        const gap = .45;
        const seg = full / n;
        final dash = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke - .5
          ..color = color;
        for (var i = 0; i < n; i++) {
          canvas.drawArc(rect, start + i * seg, seg * (1 - gap), false, dash);
        }
      case JourneyRing.split:
        const gap = .06;
        canvas.drawArc(
            rect, start + full * gap / 2, full * (.5 - gap), false, fill);
        canvas.drawArc(rect, start + full * (.5 + gap / 2), full * (.5 - gap),
            false, fill);
      case JourneyRing.segments:
        final n = math.max(1, segments);
        final seg = full / n;
        const gapRad = .22;
        for (var i = 0; i < n; i++) {
          canvas.drawArc(rect, start + i * seg + gapRad / 2, seg - gapRad,
              false, i < segmentsDone ? fill : track);
        }
    }
  }

  @override
  bool shouldRepaint(JourneyRingPainter old) =>
      old.ring != ring ||
      old.color != color ||
      old.progress != progress ||
      old.segments != segments ||
      old.segmentsDone != segmentsDone ||
      old.stroke != stroke ||
      old.showTrack != showTrack;
}

/// A progress ring whose drop leaves a pale trail that catches up a beat
/// later, so the size of a hit stays readable.
class _TrailedRing extends StatelessWidget {
  final JourneyRing ring;
  final Color color;
  final double progress;

  const _TrailedRing({
    required this.ring,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration:
            AppMotion.duration(context, const Duration(milliseconds: 1400)),
        curve: const Interval(.35, 1, curve: Curves.easeOutCubic),
        builder: (_, v, __) => CustomPaint(
          painter: JourneyRingPainter(
            ring: ring,
            color: Colors.white.withValues(alpha: .55),
            progress: v,
            showTrack: false,
          ),
        ),
      ),
      TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration:
            AppMotion.duration(context, const Duration(milliseconds: 420)),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => CustomPaint(
          painter: JourneyRingPainter(
            ring: ring,
            color: color,
            progress: v,
          ),
        ),
      ),
    ]);
  }
}

/// The split duel ring: the player's HP fills the left half from the bottom
/// up, the foe's the right half; both leave a pale trail when they drop.
class _TrailedDuelRing extends StatelessWidget {
  final double you;
  final Color youColor;
  final double foe;
  final Color foeColor;

  const _TrailedDuelRing({
    required this.you,
    required this.youColor,
    required this.foe,
    required this.foeColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget layer(Duration d, Curve curve, bool trail) =>
        TweenAnimationBuilder<Offset>(
          tween: Tween(end: Offset(you, foe)),
          duration: AppMotion.duration(context, d),
          curve: curve,
          builder: (_, v, __) => CustomPaint(
            painter: DuelRingPainter(
              you: v.dx,
              foe: v.dy,
              youColor: trail ? Colors.white.withValues(alpha: .55) : youColor,
              foeColor: trail ? Colors.white.withValues(alpha: .55) : foeColor,
              showTrack: !trail,
            ),
          ),
        );
    return Stack(fit: StackFit.expand, children: [
      layer(const Duration(milliseconds: 1400),
          const Interval(.35, 1, curve: Curves.easeOutCubic), true),
      layer(const Duration(milliseconds: 420), Curves.easeOutCubic, false),
    ]);
  }
}

/// Two half rings that meet at the top and bottom with a small gap.
class DuelRingPainter extends CustomPainter {
  final double you;
  final double foe;
  final Color youColor;
  final Color foeColor;
  final double stroke;
  final bool showTrack;

  DuelRingPainter({
    required this.you,
    required this.foe,
    required this.youColor,
    required this.foeColor,
    this.stroke = 4.5,
    this.showTrack = true,
  });

  static const _gap = .16;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    const bottom = math.pi / 2;
    const half = math.pi - 2 * _gap;
    Paint pen(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = c;
    if (showTrack) {
      canvas.drawArc(rect, bottom + _gap, half, false,
          pen(youColor.withValues(alpha: .2)));
      canvas.drawArc(rect, bottom - _gap, -half, false,
          pen(foeColor.withValues(alpha: .2)));
    }
    final y = you.clamp(0.0, 1.0), f = foe.clamp(0.0, 1.0);
    // Left half: clockwise from the bottom, through 9 o'clock.
    if (y > 0) {
      canvas.drawArc(rect, bottom + _gap, half * y, false, pen(youColor));
    }
    // Right half: anticlockwise from the bottom, through 3 o'clock.
    if (f > 0) {
      canvas.drawArc(rect, bottom - _gap, -half * f, false, pen(foeColor));
    }
  }

  @override
  bool shouldRepaint(DuelRingPainter old) =>
      old.you != you ||
      old.foe != foe ||
      old.youColor != youColor ||
      old.foeColor != foeColor ||
      old.showTrack != showTrack;
}

/// The spinning gold dashes around the button while a finisher charges.
class _ChargeRingPainter extends CustomPainter {
  final double t;
  _ChargeRingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFD27A);
    const n = 16;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, t * math.pi * 2 / 3 + i * 2 * math.pi / n,
          math.pi / n, false, p);
    }
  }

  @override
  bool shouldRepaint(_ChargeRingPainter old) => old.t != t;
}
