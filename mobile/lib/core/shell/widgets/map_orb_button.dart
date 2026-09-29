import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/map/journey/journey_state.dart';
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
  JourneyKind? _lastKind;

  @override
  void dispose() {
    _pulse.dispose();
    _pop.dispose();
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
    final s = ref.watch(journeyOrbStateProvider);
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

    final glow = s.color.withValues(alpha: .32);
    final bg = HSLColor.fromColor(s.color);
    final bgTop =
        bg.withLightness(.16).withSaturation(bg.saturation * .6).toColor();

    return Semantics(
      button: true,
      label: 'Map. ${s.semantics}',
      child: FxAnchorTarget(
        anchor: ShellAnchors.mapOrb,
        child: AppPressable(
          haptic: AppHaptic.light,
          pressedScale: .94,
          onTap: widget.onTap,
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
                    if (!_pulse.isAnimating) return const SizedBox.shrink();
                    final t = _pulse.value;
                    return Transform.scale(
                      scale: .92 + .38 * t,
                      child: Container(
                        width: kMapOrbSize,
                        height: kMapOrbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: s.color.withValues(alpha: .8 * (1 - t)),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotionTokens.micro),
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
                            color: Color(0xFF040810), spreadRadius: 5),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: s.progress),
                      duration: AppMotion.duration(
                          context, const Duration(milliseconds: 900)),
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
                  scale:
                      CurvedAnimation(parent: _pop, curve: Curves.easeOutBack),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: s.iconAsset != null
                            ? AppIconImage(s.iconAsset!, size: 30)
                            : Icon(s.icon, size: 24, color: Colors.white),
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
                          fontFeatures: const [FontFeature.tabularFigures()],
                          shadows: const [
                            Shadow(color: Color(0xCC000000), blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (s.alert && !widget.open)
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

  JourneyRingPainter({
    required this.ring,
    required this.color,
    required this.progress,
    this.segments = 0,
    this.segmentsDone = 0,
  });

  static const _stroke = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = color.withValues(alpha: .2);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    const start = -math.pi / 2;
    const full = 2 * math.pi;

    switch (ring) {
      case JourneyRing.progress:
        canvas.drawArc(rect, 0, full, false, track);
        final p = progress.clamp(0.0, 1.0);
        if (p > 0) canvas.drawArc(rect, start, full * p, false, fill);
      case JourneyRing.dashed:
        const n = 14;
        const gap = .45;
        const seg = full / n;
        final dash = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke - .5
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
      old.segmentsDone != segmentsDone;
}
