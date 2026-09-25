import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../widgets/home_card.dart';

/// Idle "you can act here" motion for the Home map card (`HomePortalCard`).
///
/// Every variant uses the same recipe: the border breathes (3.6 s), a light
/// sweep crosses the card and then the primary button (6 s), and the variant
/// adds one signature motion of its own. How much of it plays depends on
/// whether the player can act right now:
///
///  * [PortalMotion.full]    breathe + sweep + signature
///  * [PortalMotion.calm]    breathe + sweep
///  * [PortalMotion.waiting] signature only (e.g. travelling — nothing to tap)
///  * [PortalMotion.still]   nothing moves (locked, opened, cleared)
enum PortalMotion { full, calm, waiting, still }

/// Loop lengths, in seconds.
const kPortalBreath = 3.6;
const kPortalSweep = 6.0;

/// Handed to a [PortalIdle] builder while motion is running. Null otherwise,
/// so callers render their static layout when there is nothing to animate.
class PortalFx {
  PortalFx._(this.motion, this.seconds);

  final PortalMotion motion;

  /// Seconds since the loop started. Every effect derives its phase from it,
  /// so one ticker drives the whole card.
  final ValueListenable<double> seconds;

  final _phases = <double, Animation<double>>{};

  bool get breathe =>
      motion == PortalMotion.full || motion == PortalMotion.calm;
  bool get sweep => breathe;
  bool get signature =>
      motion == PortalMotion.full || motion == PortalMotion.waiting;

  /// Looping 0..1 progress with the given period (seconds).
  Animation<double> phase(double period) =>
      _phases.putIfAbsent(period, () => _PhaseAnimation(seconds, period));

  Animation<double> get breath => phase(kPortalBreath);
  Animation<double> get sweepPhase => phase(kPortalSweep);

  /// Button hooks for `HomeHeroButton(shine:, nudge:)`.
  Animation<double>? get buttonShine => sweep ? sweepPhase : null;
  Animation<double>? get buttonNudge => breathe ? breath : null;
}

class _PhaseAnimation extends Animation<double> {
  _PhaseAnimation(this._seconds, this._period);
  final ValueListenable<double> _seconds;
  final double _period;

  @override
  double get value => (_seconds.value % _period) / _period;
  @override
  AnimationStatus get status => AnimationStatus.forward;
  @override
  void addListener(VoidCallback listener) => _seconds.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _seconds.removeListener(listener);
  @override
  void addStatusListener(AnimationStatusListener listener) {}
  @override
  void removeStatusListener(AnimationStatusListener listener) {}
}

/// Owns the ticker. Runs only when [motion] isn't still and the app's motion
/// setting is full; otherwise [builder] gets a null [PortalFx].
class PortalIdle extends StatefulWidget {
  final PortalMotion motion;
  final Widget Function(BuildContext context, PortalFx? fx) builder;
  const PortalIdle({super.key, required this.motion, required this.builder});

  @override
  State<PortalIdle> createState() => _PortalIdleState();
}

class _PortalIdleState extends State<PortalIdle>
    with SingleTickerProviderStateMixin {
  final _seconds = ValueNotifier<double>(0);
  late final Ticker _ticker =
      createTicker((e) => _seconds.value = e.inMicroseconds / 1e6);
  PortalFx? _fx;

  void _sync() {
    final run =
        widget.motion != PortalMotion.still && AppMotion.isFull(context);
    if (run) {
      if (_fx?.motion != widget.motion) {
        _fx = PortalFx._(widget.motion, _seconds);
      }
      if (!_ticker.isActive) _ticker.start();
    } else {
      _fx = null;
      if (_ticker.isActive) _ticker.stop();
      _seconds.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PortalIdle old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _fx);
}

// ── Card frame: breathing border + light sweep ───────────────────────────────

/// `HomeCard` for the portal. With [fx] it breathes (or beats, when
/// [heartbeat]) and a light band sweeps across it; without it, it's the
/// plain card at the base alphas.
class PortalIdleCard extends StatelessWidget {
  final PortalFx? fx;
  final Color accent;
  final bool heartbeat;
  final double borderAlpha;
  final double glowAlpha;
  final EdgeInsets padding;
  final Widget child;

  const PortalIdleCard({
    super.key,
    required this.fx,
    required this.accent,
    required this.child,
    this.heartbeat = false,
    this.borderAlpha = 0.4,
    this.glowAlpha = 0.12,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 14),
  });

  static const _margin = 14.0;

  HomeCard _card(double b) => HomeCard(
        borderColor: accent.withValues(alpha: borderAlpha + 0.55 * b),
        glowColor: accent.withValues(alpha: glowAlpha + 0.23 * b),
        margin: const EdgeInsets.only(bottom: _margin),
        padding: padding,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final fx = this.fx;
    if (fx == null || (!fx.breathe && !fx.sweep)) return _card(0);
    final breath = fx.breath;
    final card = fx.breathe
        ? AnimatedBuilder(
            animation: breath,
            builder: (_, __) => _card(heartbeat
                ? _heartbeat(breath.value)
                : (1 - math.cos(breath.value * 2 * math.pi)) / 2),
          )
        : _card(0);
    if (!fx.sweep) return card;
    final sweep = fx.sweepPhase;
    final tint = Color.lerp(accent, Colors.white, .45)!;
    return Stack(
      children: [
        card,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: _margin,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AnimatedBuilder(
                animation: sweep,
                builder: (_, __) {
                  final p = ((sweep.value - .55) / .3).clamp(0.0, 1.0);
                  if (p <= 0 || p >= 1) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment(-1.6 + 3.2 * p, 0),
                    child: Transform(
                      transform: Matrix4.skewX(-.32),
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            tint.withValues(alpha: 0),
                            tint.withValues(alpha: .15),
                            Colors.white.withValues(alpha: .10),
                            tint.withValues(alpha: .15),
                            tint.withValues(alpha: 0),
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Two quick beats early in the loop, then rest: lub (6 %), dub (20 %).
  static double _heartbeat(double t) {
    double beat(double at, double h) {
      final d = (t - at).abs();
      return d > .07 ? 0 : h * (1 - d / .07);
    }

    return math.max(beat(.06, 1), beat(.20, .85));
  }
}

// ── Signatures ───────────────────────────────────────────────────────────────

/// Title emoji motions.
enum PortalEmojiFx {
  /// Flinch as if hit (path blocker).
  shake,

  /// Coin flip (merchant).
  coin,

  /// Rattle on its base (treasure chest).
  rattle,
}

class PortalEmoji extends StatelessWidget {
  final String emoji;
  final PortalEmojiFx effect;
  final PortalFx? fx;
  final double size;
  const PortalEmoji({
    super.key,
    required this.emoji,
    required this.effect,
    required this.fx,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(emoji, style: TextStyle(fontSize: size, height: 1.15));
    final fx = this.fx;
    if (fx == null || !fx.signature) return text;
    final a = fx.phase(switch (effect) {
      PortalEmojiFx.shake => 3.0,
      PortalEmojiFx.coin => 3.2,
      PortalEmojiFx.rattle => 2.8,
    });
    return AnimatedBuilder(
      animation: a,
      child: text,
      builder: (_, child) {
        final t = a.value;
        switch (effect) {
          case PortalEmojiFx.shake:
            if (t < .78 || t > .93) return child!;
            final k = (t - .78) / .15;
            final w = math.sin(k * math.pi * 3) * (1 - k);
            return Transform.translate(
              offset: Offset(-3 * w, 0),
              child: Transform.rotate(angle: -.14 * w, child: child),
            );
          case PortalEmojiFx.coin:
            final k = ((t - .72) / .18).clamp(0.0, 1.0);
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .002)
                ..rotateY(Curves.easeInOut.transform(k) * 2 * math.pi),
              child: child,
            );
          case PortalEmojiFx.rattle:
            if (t < .70 || t > .85) return child!;
            final k = (t - .70) / .15;
            final w = math.sin(k * math.pi * 3) * (1 - k);
            return Transform.translate(
              offset: Offset(0, -2 * (1 - k)),
              child: Transform.rotate(
                angle: .2 * w,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            );
        }
      },
    );
  }
}

/// Blinking live dot, e.g. beside a raid timer.
class PortalLiveDot extends StatelessWidget {
  final PortalFx fx;
  final Color color;
  const PortalLiveDot({super.key, required this.fx, required this.color});

  @override
  Widget build(BuildContext context) {
    final a = fx.phase(1.2);
    return AnimatedBuilder(
      animation: a,
      builder: (_, __) {
        final o = .25 + .75 * (1 - math.cos(a.value * 2 * math.pi)) / 2;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: o),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: o * .8), blurRadius: 6),
            ],
          ),
        );
      },
    );
  }
}

/// Three dots bouncing in a speech bubble (story encounter).
class PortalTypingBubble extends StatelessWidget {
  final PortalFx fx;
  final Color color;
  const PortalTypingBubble({super.key, required this.fx, required this.color});

  @override
  Widget build(BuildContext context) {
    final a = fx.phase(1.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        border: Border.all(color: color.withValues(alpha: .45)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(9),
          topRight: Radius.circular(9),
          bottomRight: Radius.circular(9),
          bottomLeft: Radius.circular(2),
        ),
      ),
      child: AnimatedBuilder(
        animation: a,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Builder(builder: (_) {
                final t = (a.value - i * .13) % 1;
                final up = t < .6 ? math.sin(t / .6 * math.pi) : 0.0;
                return Transform.translate(
                  offset: Offset(0, -3 * up),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.lerp(color, Colors.white, .35)!
                          .withValues(alpha: .4 + .6 * up),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Four-point sparkles that twinkle one after another at fractional
/// positions inside the parent (merchant goods, chest reward).
class PortalGlints extends StatelessWidget {
  final PortalFx fx;
  final List<Offset> at;
  final Color color;
  const PortalGlints({
    super.key,
    required this.fx,
    required this.at,
    this.color = const Color(0xFFFFE3A3),
  });

  @override
  Widget build(BuildContext context) {
    final a = fx.phase(3.2);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, box) => AnimatedBuilder(
          animation: a,
          builder: (_, __) => Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < at.length; i++)
                Builder(builder: (_) {
                  final t = (a.value - i * .08) % 1;
                  final s = t < .7
                      ? 0.0
                      : t < .8
                          ? (t - .7) / .1
                          : t < .9
                              ? 1 - (t - .8) / .1
                              : 0.0;
                  if (s <= 0) return const SizedBox.shrink();
                  return Positioned(
                    left: box.maxWidth * at[i].dx - 5,
                    top: box.maxHeight * at[i].dy - 5,
                    child: Transform.scale(
                      scale: .3 + .9 * s,
                      child: Opacity(
                        opacity: s,
                        child: CustomPaint(
                          size: const Size(10, 10),
                          painter: _SparkPainter(color),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final Color color;
  _SparkPainter(this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero), r = s.width / 2, k = r * .24;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + k, c.dy - k)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + k, c.dy + k)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - k, c.dy + k)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - k, c.dy - k)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.orange.withValues(alpha: .6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.color != color;
}

/// Uneven torchlight flicker, as a border/glow strength 0..1 (dungeon chip).
double portalTorch(double t) {
  const keys = [.0, .13, .21, .34, .52, .66, .81];
  const vals = [.25, .7, .15, .8, .35, .9, .2];
  var v = vals.first;
  for (var i = 0; i < keys.length; i++) {
    if (t >= keys[i]) v = vals[i];
  }
  return v;
}

// ── Progress-bar overlays ────────────────────────────────────────────────────
//
// Drawn in a Stack over `HomeProgressBar` (10 px tall). [progress] is the
// bar's fill fraction; overlays position themselves from it.

/// Raid HP: a hot ember pulsing at the edge of the remaining HP.
class PortalBarEmber extends StatelessWidget {
  final PortalFx fx;
  final double progress;
  const PortalBarEmber({super.key, required this.fx, required this.progress});

  @override
  Widget build(BuildContext context) {
    final a = fx.phase(1.2);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, box) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: box.maxWidth * progress.clamp(0.0, 1.0) - 8,
              top: box.maxHeight / 2 - 8,
              child: AnimatedBuilder(
                animation: a,
                builder: (_, __) {
                  final p = (1 - math.cos(a.value * 2 * math.pi)) / 2;
                  return Transform.scale(
                    scale: .8 + .45 * p,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFFFFD2A8)
                              .withValues(alpha: .45 + .55 * p),
                          AppColors.red.withValues(alpha: .8 * (.45 + .55 * p)),
                          AppColors.red.withValues(alpha: 0),
                        ], stops: const [
                          0,
                          .45,
                          1
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Boss zone: small embers rising off the bar and fading.
class PortalRisingEmbers extends StatelessWidget {
  final PortalFx fx;
  const PortalRisingEmbers({super.key, required this.fx});

  static const _embers = [(.30, .0, -6.0), (.55, .33, 5.0), (.78, .66, -3.0)];

  @override
  Widget build(BuildContext context) {
    final a = fx.phase(2.4);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, box) => AnimatedBuilder(
          animation: a,
          builder: (_, __) => Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (x, delay, dx) in _embers)
                Builder(builder: (_) {
                  final t = (a.value - delay) % 1;
                  final o = t < .15 ? t / .15 : 1 - (t - .15) / .85;
                  return Positioned(
                    left: box.maxWidth * x + dx * t,
                    top: box.maxHeight / 2 -
                        2 -
                        34 * Curves.easeOut.transform(t),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFB199).withValues(alpha: o),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.red.withValues(alpha: o),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Travelling: the hero token stands on the bar at the player's position,
/// hopping and inching forward. Footprints fade behind it, the bar just ahead
/// glows, and a flag waves at the destination end.
///
/// Needs [kPortalWalkHeadroom] of free space above the bar.
const kPortalWalkHeadroom = 14.0;

class PortalHeroWalk extends StatelessWidget {
  final PortalFx fx;
  final double progress;
  final String avatarEmoji;
  const PortalHeroWalk({
    super.key,
    required this.fx,
    required this.progress,
    required this.avatarEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final hop = fx.phase(.9);
    final walk = fx.phase(3.6);
    final flag = fx.phase(1.2);
    final p = progress.clamp(0.0, 1.0);
    return IgnorePointer(
      child: LayoutBuilder(builder: (_, box) {
        final w = box.maxWidth, h = box.maxHeight, x = w * p;
        return AnimatedBuilder(
          animation: hop,
          builder: (_, __) {
            final wt = walk.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Glow on the bar just ahead of the hero.
                if (p < 1)
                  Positioned(
                    left: x,
                    top: 0,
                    height: h,
                    width: math.min(36, w - x),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(h / 2),
                        gradient: LinearGradient(colors: [
                          AppColors.purple.withValues(
                              alpha: .2 +
                                  .3 * (1 - math.cos(wt * 2 * math.pi)) / 2),
                          AppColors.purple.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                // Footprints behind, appearing one after another and fading.
                for (var i = 0; i < 4; i++)
                  Builder(builder: (_) {
                    final t = (wt - i * .25) % 1;
                    final o =
                        t < .08 ? t / .08 : math.max(0.0, 1 - (t - .08) / .52);
                    final fx0 = x - 14 - (3 - i) * 12.0;
                    if (fx0 < 2 || o <= 0) return const SizedBox.shrink();
                    return Positioned(
                      left: fx0,
                      top: i.isEven ? 2 : 3.5,
                      child: Container(
                        width: 4,
                        height: 5,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFCFE4FF).withValues(alpha: .8 * o),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                // Destination flag.
                Positioned(
                  right: -2,
                  bottom: h / 2 - 1,
                  child: _Flag(t: flag.value),
                ),
                // The hero token.
                Positioned(
                  left:
                      x - 13 + (-4 + 7 * (1 - math.cos(wt * 2 * math.pi)) / 2),
                  bottom: h / 2 - 2 + 4 * math.sin(hop.value * math.pi).abs(),
                  child: Transform.rotate(
                    angle: .07 * math.sin(hop.value * 2 * math.pi),
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0E1A2E),
                        border: Border.all(color: AppColors.blue, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: .5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(avatarEmoji,
                          style: const TextStyle(fontSize: 14, height: 1)),
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
}

class _Flag extends StatelessWidget {
  final double t;
  const _Flag({required this.t});

  @override
  Widget build(BuildContext context) {
    final s = math.sin(t * 2 * math.pi);
    return SizedBox(
      width: 14,
      height: 20,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 2,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFC9D1D9),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            left: 2,
            top: 0,
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.diagonal3Values(.9 + .1 * s, 1, 1)
                ..setEntry(1, 0, .12 * s),
              child: ClipPath(
                clipper: _PennantClipper(),
                child: Container(width: 12, height: 8, color: AppColors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PennantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, s.height / 2)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(_PennantClipper old) => false;
}
