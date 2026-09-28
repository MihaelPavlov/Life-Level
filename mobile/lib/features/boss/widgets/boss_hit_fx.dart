import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';

/// Last HP the player actually saw for each boss / blocker, keyed by id.
///
/// A hit plays once, wherever the player first sees the drop: the home
/// card, the map's blocker sheet or the battle view. Screens that show HP
/// without a [BossHitScope] call [markSeen] so the drop isn't replayed.
class BossHitMemory {
  BossHitMemory._();

  static final _seen = <String, int>{};

  static int? seen(String id) => _seen[id];

  static void markSeen(String id, int hp) => _seen[id] = hp;
}

/// The slash that cuts across a boss portrait on a hit.
class BossSlash {
  BossSlash._();

  static void play(
    BuildContext context,
    Offset center, {
    double width = 170,
    double thickness = 5,
  }) {
    RewardFx.run(
      context,
      duration: const Duration(milliseconds: 360),
      builder: (t, origin) => _slash(center - origin, t, width, thickness),
    );
  }

  static Widget _slash(Offset c, double t, double width, double thickness) {
    final grow = (t / .5).clamp(0.0, 1.0);
    final fade = t < .5 ? 1.0 : 1 - (t - .5) / .5;
    return Positioned(
      left: c.dx - width / 2,
      top: c.dy - thickness / 2,
      child: Opacity(
        opacity: fade,
        child: Transform.rotate(
          angle: -35 * math.pi / 180,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1.3 * grow, 1, 1),
            child: Container(
              width: width,
              height: thickness,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(colors: [
                  Colors.transparent,
                  Colors.white,
                  Color(0xFFFFD0CC),
                  Colors.transparent,
                ], stops: [
                  0,
                  .4,
                  .6,
                  1
                ]),
                boxShadow: const [
                  BoxShadow(color: Colors.white, blurRadius: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One frame of the "slash + ember burn" hit, in HP terms.
class BossHitFrame {
  /// True while a hit plays (or waits to start).
  final bool active;

  /// HP number to display — counts down during a hit.
  final int shownHp;

  /// HP the red fill shows — snaps to the new value as the slash lands.
  final int barHp;

  /// HP the orange ember layer still covers behind the fill; burns down to
  /// [barHp]. Null when idle.
  final int? emberHp;

  /// Horizontal shake for the whole card / section.
  final double shakeDx;

  /// Recoil for the portrait that takes the slash.
  final double portraitDx;

  /// White flash over the portrait, 0..1.
  final double flash;

  const BossHitFrame({
    required this.active,
    required this.shownHp,
    required this.barHp,
    required this.emberHp,
    required this.shakeDx,
    required this.portraitDx,
    required this.flash,
  });
}

typedef BossHitBuilder = Widget Function(
    BuildContext context, BossHitFrame hit, GlobalKey portraitKey);

/// Plays the slash + ember burn when [hp] drops below what the player last
/// saw for [hitId] — on update, or on first mount after damage dealt
/// elsewhere (e.g. a workout logged from another tab).
///
/// Waits while tickers are muted (hidden tab, covered by a shell overlay)
/// so the hit plays when the player can actually see it. Attach
/// `portraitKey` to the portrait the slash should cut across.
class BossHitScope extends StatefulWidget {
  final String hitId;
  final int hp;
  final int maxHp;

  /// Delay before the hit starts, e.g. to let a sheet finish sliding in.
  final Duration startDelay;
  final double slashWidth;
  final double shakeAmplitude;
  final double recoil;
  final BossHitBuilder builder;

  const BossHitScope({
    super.key,
    required this.hitId,
    required this.hp,
    required this.maxHp,
    required this.builder,
    this.startDelay = Duration.zero,
    this.slashWidth = 170,
    this.shakeAmplitude = 6,
    this.recoil = 10,
  });

  @override
  State<BossHitScope> createState() => _BossHitScopeState();
}

class _BossHitScopeState extends State<BossHitScope>
    with SingleTickerProviderStateMixin {
  static const _hitMs = 1300.0;
  final _portraitKey = GlobalKey();
  late final AnimationController _hit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..addListener(() => setState(() {}));
  int _from = 0;
  int _to = 0;
  bool _pending = false;

  double get _t => _hit.value * _hitMs;
  bool get _active => _pending || _hit.isAnimating;

  double _phase(double start, double len, [Curve curve = Curves.linear]) =>
      curve.transform(((_t - start) / len).clamp(0.0, 1.0));

  int _lerp(double p) => (_from + (_to - _from) * p).round();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also runs on first mount and whenever TickerMode flips back on.
    _check();
  }

  @override
  void didUpdateWidget(covariant BossHitScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hitId != widget.hitId) {
      _hit.stop();
      _pending = false;
    }
    _check();
  }

  void _check() {
    if (!TickerMode.of(context)) return;
    final id = widget.hitId;
    final hp = widget.hp;
    final seen = BossHitMemory.seen(id);
    BossHitMemory.markSeen(id, hp);
    if (seen == null || hp >= seen) return;
    if (!RewardFx.enabled(context)) return;
    // A second hit mid-animation continues from what's on screen.
    _from = _active ? _frame().shownHp : seen;
    _to = hp;
    if (widget.startDelay > Duration.zero) {
      _pending = true;
      Future.delayed(widget.startDelay, () {
        if (!mounted || !_pending) return;
        _pending = false;
        _start();
      });
    } else {
      _pending = false;
      _start();
    }
  }

  void _start() {
    _hit.forward(from: 0);
    AppMotion.haptic(AppHaptic.light);
    final damage = _from - _to;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = RewardFx.centerOf(_portraitKey);
      if (c == null) return;
      BossSlash.play(context, c, width: widget.slashWidth);
      RewardFx.burst(context, c, AppColors.red,
          count: 12, distance: 60, delay: const Duration(milliseconds: 120));
      RewardFx.floatText(
        context,
        c + const Offset(30, -60),
        '−${_group(damage)}',
        AppColors.orange,
        fontSize: 24,
        rise: 28,
        popScale: 1.2,
        duration: const Duration(milliseconds: 1300),
        delay: const Duration(milliseconds: 120),
      );
    });
  }

  BossHitFrame _frame() {
    if (!_active) {
      return BossHitFrame(
        active: false,
        shownHp: widget.hp,
        barHp: widget.hp,
        emberHp: null,
        shakeDx: 0,
        portraitDx: 0,
        flash: 0,
      );
    }
    if (_pending) {
      return BossHitFrame(
        active: true,
        shownHp: _from,
        barHp: _from,
        emberHp: null,
        shakeDx: 0,
        portraitDx: 0,
        flash: 0,
      );
    }
    final shake = _phase(120, 380);
    final recoil = _phase(120, 500);
    return BossHitFrame(
      active: true,
      shownHp: _lerp(_phase(120, 700, Curves.easeOutCubic)),
      barHp: _t < 120 ? _from : _to,
      emberHp: _lerp(_phase(320, 900, const Cubic(.5, 0, .6, 1))),
      shakeDx: shake <= 0 || shake >= 1
          ? 0
          : math.sin(shake * math.pi * 6) *
              widget.shakeAmplitude *
              (1 - shake),
      portraitDx: -widget.recoil * math.sin(recoil * math.pi) * (1 - recoil),
      flash: _t >= 120 ? .45 * (1 - _phase(120, 300)) : 0,
    );
  }

  @override
  void dispose() {
    _hit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _frame(), _portraitKey);
}

/// Wraps a portrait with the hit's recoil and white flash.
class BossHitPortrait extends StatelessWidget {
  final BossHitFrame hit;
  final GlobalKey portraitKey;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Widget child;

  const BossHitPortrait({
    super.key,
    required this.hit,
    required this.portraitKey,
    required this.child,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(hit.portraitDx, 0),
      child: Container(
        key: portraitKey,
        foregroundDecoration: hit.flash > 0
            ? BoxDecoration(
                shape: shape,
                borderRadius: borderRadius,
                color: Colors.white.withValues(alpha: hit.flash),
              )
            : null,
        child: child,
      ),
    );
  }
}

String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
