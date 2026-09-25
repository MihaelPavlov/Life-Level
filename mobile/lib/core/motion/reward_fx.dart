import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_motion.dart';

/// Remembers where a widget is, for effects that start or end on it.
///
/// Unlike a [GlobalKey] it never reparents anything, so it's safe on
/// widgets whose parent changes between frames (list rows that re-sort,
/// tiles that swap wrappers when their state changes).
class FxAnchor {
  BuildContext? _context;

  Rect? get rect {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Offset? get center => rect?.center;
}

/// Registers its position on [anchor] every build.
class FxAnchorTarget extends StatelessWidget {
  final FxAnchor anchor;
  final Widget child;
  const FxAnchorTarget({super.key, required this.anchor, required this.child});

  @override
  Widget build(BuildContext context) {
    anchor._context = context;
    return child;
  }
}

/// One-shot celebration effects drawn on the root overlay in global
/// coordinates, so they can travel between widgets anywhere on screen
/// (a reward tile flying into a badge, a burst on a stat, a light beam out
/// of a chest…). Every effect is its own self-removing [OverlayEntry].
///
/// All helpers are no-ops when decorative motion is off/reduced
/// ([AppMotion.allowsDecorativeMotion]), except [fly], which completes
/// immediately so callers can keep their sequencing.
class RewardFx {
  RewardFx._();

  static final _rng = math.Random();

  static bool enabled(BuildContext context) =>
      AppMotion.allowsDecorativeMotion(context);

  /// Global rect of the widget holding [key], or null when not laid out.
  static Rect? rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static Offset? centerOf(GlobalKey key) => rectOf(key)?.center;

  /// Inserts an entry that lives for [duration] (+[delay]) and rebuilds
  /// [builder] every frame with the eased-free progress `t` in 0..1 and
  /// the overlay's global origin (subtract it from global positions).
  static Future<void> run(
    BuildContext context, {
    required Duration duration,
    Duration delay = Duration.zero,
    required Widget Function(double t, Offset origin) builder,
  }) {
    final done = Completer<void>();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      done.complete();
      return done.future;
    }
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _FxHost(
          duration: duration,
          delay: delay,
          overlay: overlay,
          builder: builder,
          onDone: () {
            entry.remove();
            if (!done.isCompleted) done.complete();
          },
        ),
      ),
    );
    // Effects are often triggered from didUpdateWidget, i.e. mid-build;
    // inserting into the Overlay then would rebuild an ancestor during the
    // build phase. Defer to the end of the frame in that case.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (overlay.mounted) {
          overlay.insert(entry);
        } else if (!done.isCompleted) {
          done.complete();
        }
      });
    } else {
      overlay.insert(entry);
    }
    return done.future;
  }

  /// Flies [child] from [from] to [to] (global) along a quadratic arc.
  /// Completes when it lands.
  static Future<void> fly(
    BuildContext context, {
    required Widget child,
    required Offset from,
    required Offset to,
    double lift = -40,
    double sideways = 0,
    double endScale = .6,
    double spinTurns = 0,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
    Curve curve = const Cubic(.45, 0, .55, 1),
  }) {
    if (!enabled(context)) return Future.value();
    final control = Offset(
      (from.dx + to.dx) / 2 + sideways,
      math.min(from.dy, to.dy) + lift,
    );
    return run(
      context,
      duration: duration,
      delay: delay,
      builder: (t, origin) {
        final e = curve.transform(t);
        final u = 1 - e;
        final p = from * (u * u) + control * (2 * u * e) + to * (e * e);
        return _at(
          p - origin,
          Transform.rotate(
            angle: spinTurns * 2 * math.pi * e,
            child: Transform.scale(scale: 1 + (endScale - 1) * e, child: child),
          ),
        );
      },
    );
  }

  /// Radial burst of glowing dots.
  static void burst(
    BuildContext context,
    Offset at,
    Color color, {
    int count = 10,
    double distance = 40,
    double size = 6,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
  }) {
    if (!enabled(context)) return;
    final parts = List.generate(count, (i) {
      final a = i / count * 2 * math.pi + (_rng.nextDouble() - .5) * .6;
      return (a, distance * (.6 + _rng.nextDouble() * .5));
    });
    run(
      context,
      duration: duration,
      delay: delay,
      builder: (t, origin) => CustomPaint(
        size: Size.infinite,
        painter: _BurstPainter(at - origin, parts, color, size,
            const Cubic(.1, .7, .3, 1).transform(t)),
      ),
    );
  }

  /// Expanding ring (shockwave).
  static void ring(
    BuildContext context,
    Offset at,
    Color color, {
    double maxRadius = 48,
    double stroke = 2,
    Duration duration = const Duration(milliseconds: 600),
    Duration delay = Duration.zero,
  }) {
    if (!enabled(context)) return;
    run(
      context,
      duration: duration,
      delay: delay,
      builder: (t, origin) => CustomPaint(
        size: Size.infinite,
        painter: _RingPainter(at - origin, color, maxRadius, stroke,
            const Cubic(.1, .7, .3, 1).transform(t)),
      ),
    );
  }

  /// Text that pops in, rises and fades (e.g. "+20 pts", "CRIT −2,480").
  static void floatText(
    BuildContext context,
    Offset at,
    String text,
    Color color, {
    double rise = 34,
    double fontSize = 15,
    double popScale = 1.05,
    bool pill = false,
    Duration duration = const Duration(milliseconds: 1100),
    Duration delay = Duration.zero,
  }) {
    if (!enabled(context)) return;
    final text0 = Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.none,
        shadows: pill ? null : [Shadow(color: color, blurRadius: 10)],
      ),
    );
    // A pill reads cleanly over busy content (lists, other rewards).
    final label = !pill
        ? text0
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xF0080E14),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: color.withValues(alpha: .6)),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: .3), blurRadius: 12),
              ],
            ),
            child: text0,
          );
    run(
      context,
      duration: duration,
      delay: delay,
      builder: (t, origin) {
        final inT = (t / .2).clamp(0.0, 1.0);
        final opacity = t < .2 ? inT : (1 - (t - .2) / .8).clamp(0.0, 1.0);
        final dy = t < .2 ? 6 - 12 * inT : -6 - (rise - 6) * ((t - .2) / .8);
        final scale = t < .2 ? .7 + (popScale - .7) * inT : 1.0;
        return _at(
          at - origin + Offset(0, dy),
          Opacity(
              opacity: opacity,
              child: Transform.scale(scale: scale, child: label)),
        );
      },
    );
  }

  /// Vertical light beam rising from [base] (e.g. out of an opened chest).
  static void beam(
    BuildContext context,
    Offset base, {
    double width = 80,
    double height = 240,
    Color color = const Color(0xFFFFE28C),
    Duration duration = const Duration(milliseconds: 1100),
  }) {
    if (!enabled(context)) return;
    run(
      context,
      duration: duration,
      builder: (t, origin) {
        final grow = Curves.easeOut.transform((t / .4).clamp(0.0, 1.0));
        final fade = t < .6 ? 1.0 : 1 - (t - .6) / .4;
        final p = base - origin;
        return Positioned(
          left: p.dx - width / 2,
          top: p.dy - height,
          width: width,
          height: height,
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(1, grow, 1),
              child: ClipPath(
                clipper: _BeamClipper(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        color.withValues(alpha: .9),
                        color.withValues(alpha: 0)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// A fountain of confetti thrown up from [at] that tumbles back down.
  static void confetti(
    BuildContext context,
    Offset at, {
    int count = 34,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    if (!enabled(context)) return;
    const palette = [
      Color(0xFFFFA11C),
      Color(0xFFFFD27A),
      Color(0xFF3594FF),
      Color(0xFFB03CEB),
      Color(0xFF00CA50),
      Color(0xFFFF5C8A),
      Color(0xFF38D9C8),
    ];
    final pieces = List.generate(count, (i) {
      final a = -math.pi * (.1 + .8 * _rng.nextDouble());
      return _Confetto(
        angle: a,
        speed: 260 + 200 * _rng.nextDouble(),
        drift: (_rng.nextDouble() - .5) * 60,
        spin: (_rng.nextDouble() - .5) * 14,
        flip: 4 + _rng.nextDouble() * 8,
        size: i % 3 == 0 ? const Size(10, 6) : const Size(7, 13),
        color: palette[i % palette.length],
      );
    });
    run(
      context,
      duration: duration,
      builder: (t, origin) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(
            at - origin, pieces, t, duration.inMilliseconds / 1000),
      ),
    );
  }

  /// Rotating wedges of light behind a reward (claim moments).
  static void rays(
    BuildContext context,
    Offset at,
    Color color, {
    double radius = 60,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    if (!enabled(context)) return;
    run(
      context,
      duration: duration,
      builder: (t, origin) => CustomPaint(
        size: Size.infinite,
        painter: _RaysPainter(at - origin, color, radius, t),
      ),
    );
  }

  /// Sparkles that drift upward from around [at].
  static void sparkles(
    BuildContext context,
    Offset at, {
    int count = 12,
    double spread = 30,
    double rise = 140,
    Color color = const Color(0xFFFFE9A8),
  }) {
    if (!enabled(context)) return;
    for (var i = 0; i < count; i++) {
      final x = (_rng.nextDouble() - .5) * 2 * spread;
      final drift = (_rng.nextDouble() - .5) * 30;
      final r = rise * (.7 + _rng.nextDouble() * .5);
      run(
        context,
        duration: Duration(milliseconds: 900 + _rng.nextInt(500)),
        delay: Duration(milliseconds: 120 + i * 55),
        builder: (t, origin) {
          final o = t < .3 ? t / .3 : 1 - (t - .3) / .7;
          final p = at - origin + Offset(x + drift * t, -r * t);
          return _at(
            p,
            Opacity(
              opacity: o.clamp(0.0, 1.0),
              child: Icon(Icons.auto_awesome,
                  size: 10 + 4 * math.sin(t * math.pi), color: color),
            ),
          );
        },
      );
    }
  }

  static Widget _at(Offset p, Widget child) => Positioned(
        left: p.dx,
        top: p.dy,
        child: FractionalTranslation(
          translation: const Offset(-.5, -.5),
          child: child,
        ),
      );
}

class _FxHost extends StatefulWidget {
  final Duration duration;
  final Duration delay;
  final OverlayState overlay;
  final Widget Function(double t, Offset origin) builder;
  final VoidCallback onDone;

  const _FxHost({
    required this.duration,
    required this.delay,
    required this.overlay,
    required this.builder,
    required this.onDone,
  });

  @override
  State<_FxHost> createState() => _FxHostState();
}

class _FxHostState extends State<_FxHost> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)
        ..addListener(() => setState(() {}))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        });
  bool _started = false;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _delay = Timer(widget.delay, () {
      if (!mounted) return;
      setState(() => _started = true);
      _c.forward();
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return const SizedBox.shrink();
    final box = widget.overlay.context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    // Effects live on the root overlay, above the page's Material — give
    // them their own so text gets the app's type style, not the debug
    // fallback.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.builder(_c.value, origin),
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Offset at;
  final List<(double, double)> parts;
  final Color color;
  final double size;
  final double t;
  _BurstPainter(this.at, this.parts, this.color, this.size, this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final glow = Paint()
      ..color = color.withValues(alpha: 1 - t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final core = Paint()..color = color.withValues(alpha: 1 - t);
    for (final (a, d) in parts) {
      final p = at + Offset(math.cos(a), math.sin(a)) * d * t;
      final r = size / 2 * (1 - .7 * t);
      canvas.drawCircle(p, r * 1.8, glow);
      canvas.drawCircle(p, r, core);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

class _RingPainter extends CustomPainter {
  final Offset at;
  final Color color;
  final double maxRadius, stroke, t;
  _RingPainter(this.at, this.color, this.maxRadius, this.stroke, this.t);

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawCircle(
      at,
      maxRadius * (.15 + .85 * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 1 - t),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

class _BeamClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * .3, s.height)
    ..lineTo(s.width * .7, s.height)
    ..lineTo(s.width, 0)
    ..lineTo(0, 0)
    ..close();

  @override
  bool shouldReclip(_BeamClipper old) => false;
}

class _RaysPainter extends CustomPainter {
  final Offset at;
  final Color color;
  final double radius, t;
  _RaysPainter(this.at, this.color, this.radius, this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final opacity = t < .4 ? t / .4 : 1 - (t - .4) / .6;
    final r = radius * (.3 + .9 * Curves.easeOut.transform(t));
    final paint = Paint()
      ..shader = RadialGradient(colors: [
        color.withValues(alpha: .6 * opacity),
        color.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(center: at, radius: r));
    const n = 12;
    final spin = t * math.pi * 2 / 3;
    for (var i = 0; i < n; i++) {
      final a = spin + i * 2 * math.pi / n;
      canvas.drawPath(
        Path()
          ..moveTo(at.dx, at.dy)
          ..arcTo(Rect.fromCircle(center: at, radius: r), a, math.pi / n * .7,
              false)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t;
}

class _Confetto {
  final double angle, speed, drift, spin, flip;
  final Size size;
  final Color color;
  const _Confetto({
    required this.angle,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.flip,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final Offset at;
  final List<_Confetto> pieces;
  final double t, seconds;
  _ConfettiPainter(this.at, this.pieces, this.t, this.seconds);

  static const _gravity = 620.0;

  @override
  void paint(Canvas canvas, Size s) {
    final sec = t * seconds;
    final fade = t < .75 ? 1.0 : 1 - (t - .75) / .25;
    final paint = Paint();
    for (final p in pieces) {
      // Air drag slows the throw; gravity pulls it back down.
      final drag = 1 - math.exp(-2.2 * sec);
      final pos = at +
          Offset(
              math.cos(p.angle) * p.speed * drag / 2.2 + p.drift * sec,
              math.sin(p.angle) * p.speed * drag / 2.2 +
                  .5 * _gravity * sec * sec * .55);
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * sec);
      canvas.scale(1, math.cos(p.flip * sec));
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size.width, height: p.size.height),
          paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
