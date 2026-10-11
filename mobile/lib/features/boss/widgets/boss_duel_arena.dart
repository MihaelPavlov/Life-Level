import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../gear/widgets/gear_paperdoll.dart';
import '../../items/models/item_models.dart';
import 'boss_icon.dart';

/// The top of the boss battle screen (design: Boss Screen Redesign canvas,
/// "C2"): your hero facing the boss over the region's scene.
///
/// At rest the boss breathes, your hero bobs and embers drift up. The screen
/// bumps [exchange] for each real turn (a live hit, or an unseen turn from
/// the replay finder): your hero lunges and the boss flinches with a white
/// flash (the screen draws the slash and damage number on [bossKey]); when
/// [counter] is true the boss then lunges back, the arena shakes, the edges
/// flash red and your hero recoils with [counterDamage] floating up.
class BossDuelArena extends StatefulWidget {
  final String bossName;

  /// Emoji or asset fallback when the boss has no full art.
  final String bossIcon;
  final String? backgroundAsset;
  final CharacterEquipmentResponse? equipment;
  final GlobalKey bossKey;
  final GlobalKey heroKey;
  final int exchange;
  final int? counterDamage;
  final int? counterBlocked;

  /// False when the boss didn't hit back (you were recovering, or the hit
  /// finished him).
  final bool counter;

  /// Height of the fight itself (boss + hero).
  static const double height = 300;

  /// Extra scene drawn above the fight, so the backdrop runs up behind the
  /// screen's top bar and tag.
  final double topInset;

  /// Extra scene below the fight before it fades into the page.
  final double bottomExtend;

  const BossDuelArena({
    super.key,
    required this.bossName,
    required this.bossIcon,
    required this.backgroundAsset,
    required this.equipment,
    required this.bossKey,
    required this.heroKey,
    this.exchange = 0,
    this.counterDamage,
    this.counterBlocked,
    this.counter = true,
    this.topInset = 0,
    this.bottomExtend = 0,
  });

  @override
  State<BossDuelArena> createState() => _BossDuelArenaState();
}

// Exchange timeline (ms).
const _exMs = 2000.0;
const _hitAt = 260.0; // your blow lands
const _counterAt = 1050.0; // his blow lands

class _BossDuelArenaState extends State<BossDuelArena>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  late final AnimationController _ex = AnimationController(
      vsync: this, duration: Duration(milliseconds: _exMs.round()));
  bool _counterNow = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.isFull(context)) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle.stop();
    }
  }

  @override
  void didUpdateWidget(covariant BossDuelArena old) {
    super.didUpdateWidget(old);
    if (widget.exchange != old.exchange) _play();
  }

  @override
  void dispose() {
    _idle.dispose();
    _ex.dispose();
    super.dispose();
  }

  void _play() {
    if (!RewardFx.enabled(context)) return;
    _counterNow = widget.counter;
    _ex.forward(from: 0);
    if (!_counterNow) return;
    final taken = widget.counterDamage;
    final blocked = widget.counterBlocked ?? 0;
    Future<void>.delayed(Duration(milliseconds: _counterAt.round()), () {
      if (!mounted) return;
      AppMotion.haptic(AppHaptic.medium);
      final c = RewardFx.centerOf(widget.heroKey);
      if (c == null || taken == null || taken <= 0) return;
      RewardFx.floatText(
          context, c + const Offset(0, -70), '−$taken', AppColors.red,
          fontSize: 24,
          rise: 26,
          popScale: 1.2,
          duration: const Duration(milliseconds: 1100));
      if (blocked > 0) {
        RewardFx.floatText(context, c + const Offset(46, -36),
            '$blocked blocked', AppColors.blue,
            fontSize: 13,
            rise: 16,
            duration: const Duration(milliseconds: 1100),
            delay: const Duration(milliseconds: 120));
      }
    });
  }

  double get _ms => _ex.isAnimating ? _ex.value * _exMs : -1;

  /// 0→1→0 bump over [start, start+len].
  double _bump(double start, double len) {
    final p = ((_ms - start) / len).clamp(0.0, 1.0);
    return p <= 0 || p >= 1 ? 0 : math.sin(p * math.pi);
  }

  double _fade(double start, double len) {
    final p = ((_ms - start) / len).clamp(0.0, 1.0);
    return p <= 0 || p >= 1 ? 0 : 1 - p;
  }

  @override
  Widget build(BuildContext context) {
    final bossArt = AppIcons.bossAssetForName(widget.bossName);
    return IgnorePointer(
      child: SizedBox(
        height: BossDuelArena.height + widget.topInset + widget.bottomExtend,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _ex]),
          builder: (context, _) {
            final t = _idle.value * 2 * math.pi;
            // Shake when his blow lands.
            final shakeP = ((_ms - _counterAt) / 260).clamp(0.0, 1.0);
            final shake = !_counterNow || shakeP <= 0 || shakeP >= 1
                ? 0.0
                : math.sin(shakeP * math.pi * 6) * 6 * (1 - shakeP);
            final heroLunge = _bump(0, 320);
            final c = _counterNow ? 1.0 : 0.0;
            final heroRecoil = _bump(_counterAt, 260) * c;
            final bossFlinch = _bump(_hitAt, 260);
            final bossLunge = _bump(_counterAt - 120, 420) * c;
            final flash = _fade(_hitAt, 220);
            final heroTint = _fade(_counterAt, 300) * c;
            final vignette = _fade(_counterAt, 520) * c;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(shake, 0),
                    child: _scene(),
                  ),
                ),
                Positioned(
                  top: widget.topInset,
                  left: 0,
                  right: 0,
                  height: BossDuelArena.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Ground glows.
                      Positioned(
                        right: 18,
                        top: 232,
                        child: _groundGlow(
                            AppColors.red, 220, 40, .75 + .25 * math.sin(t)),
                      ),
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: _groundGlow(AppColors.blue, 170, 30, .8),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child:
                              CustomPaint(painter: _EmberPainter(_idle.value)),
                        ),
                      ),
                      // The boss: lunge > flinch > breathe.
                      Positioned(
                        right: 4 + shake,
                        top: 6,
                        child: Transform.translate(
                          offset: Offset(-30 * bossLunge + 10 * bossFlinch,
                              22 * bossLunge),
                          child: Transform.scale(
                            scale: (1 + .035 * math.sin(t)) *
                                (1 + .07 * bossLunge),
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              key: widget.bossKey,
                              width: 250,
                              height: 250,
                              child: bossArt != null
                                  ? _flashing(bossArt, flash, Colors.white)
                                  : Center(
                                      child: BossIcon(
                                          icon: widget.bossIcon,
                                          size: 160,
                                          emojiSize: 96)),
                            ),
                          ),
                        ),
                      ),
                      // Your hero: recoil > lunge > bob.
                      Positioned(
                        left: 34 + shake,
                        bottom: 10,
                        child: Transform.translate(
                          offset: Offset(34 * heroLunge - 8 * heroRecoil,
                              -14 * heroLunge - 5 * math.sin(t * 1.25)),
                          child: Transform.rotate(
                            angle: .07 * heroLunge,
                            child: KeyedSubtree(
                              key: widget.heroKey,
                              child: _hero(heroTint),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Red edges when he hits you.
                if (vignette > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: .95,
                            colors: [
                              Colors.transparent,
                              AppColors.red.withValues(alpha: .55 * vignette),
                            ],
                            stops: const [.55, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _scene() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.backgroundAsset != null)
          Image.asset(widget.backgroundAsset!,
              fit: BoxFit.cover, alignment: const Alignment(0, -.2)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF060B10).withValues(alpha: .7),
                const Color(0xFF060B10).withValues(alpha: .15),
                const Color(0xFF060B10).withValues(alpha: .05),
                const Color(0xFF060B10).withValues(alpha: .35),
                const Color(0xFF060B10),
              ],
              stops: const [0, .18, .45, .78, 1],
            ),
          ),
        ),
      ],
    );
  }

  Widget _groundGlow(Color c, double w, double h, double strength) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
        gradient: RadialGradient(colors: [
          c.withValues(alpha: .45 * strength),
          c.withValues(alpha: 0),
        ]),
      ),
    );
  }

  /// [asset] with a [color] wash over its opaque pixels at [amount].
  Widget _flashing(String asset, double amount, Color color) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.contain, gaplessPlayback: true),
        if (amount > 0)
          Opacity(
            opacity: amount.clamp(0.0, 1.0),
            child: Image.asset(asset,
                fit: BoxFit.contain,
                color: color,
                colorBlendMode: BlendMode.srcATop,
                gaplessPlayback: true),
          ),
      ],
    );
  }

  Widget _hero(double tint) {
    const h = 190.0;
    final Widget body = widget.equipment == null
        ? Image.asset(AppIcons.gearBaseRender, height: h, fit: BoxFit.contain)
        : GearPaperDoll(equipment: widget.equipment!, height: h);
    if (tint <= 0) return body;
    return Stack(
      children: [
        body,
        Positioned.fill(
          child: Opacity(
            opacity: (tint * .7).clamp(0.0, 1.0),
            child: ColorFiltered(
              colorFilter:
                  const ColorFilter.mode(AppColors.red, BlendMode.srcATop),
              child: body,
            ),
          ),
        ),
      ],
    );
  }
}

/// Embers drifting up through the arena.
class _EmberPainter extends CustomPainter {
  final double t;
  _EmberPainter(this.t);

  static const _seeds = [
    (.15, 0.0, 6.0),
    (.38, .35, -5.0),
    (.6, .7, 7.0),
    (.82, .2, -8.0),
    (.28, .55, 4.0),
    (.72, .9, -3.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final (x, offset, drift) in _seeds) {
      final p = (t * 1.6 + offset) % 1.0;
      final opacity = p < .15 ? p / .15 : 1 - (p - .15) / .85;
      paint.color = const Color(0xFFFF9A5C).withValues(alpha: .8 * opacity);
      canvas.drawCircle(
        Offset(size.width * x + drift * p * 4, size.height * (1 - p * .8)),
        1.6 + (1 - p),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.t != t;
}
