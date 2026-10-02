import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../models/boss_list_item.dart';
import '../widgets/boss_icon.dart';

/// Full-screen "Boss slain": spinning rays, a crack across the portrait,
/// confetti, the XP reward counting up and a gold Claim button.
Future<void> showBossSlainTakeover(BuildContext context, BossListItem boss) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Boss slain',
    barrierColor: const Color(0xF0040810),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => _BossSlain(boss: boss),
    transitionBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
  );
}

class _BossSlain extends StatefulWidget {
  final BossListItem boss;
  const _BossSlain({required this.boss});

  @override
  State<_BossSlain> createState() => _BossSlainState();
}

class _BossSlainState extends State<_BossSlain> with TickerProviderStateMixin {
  late final _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))
        ..repeat();
  late final _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..forward();
  late final _shine = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppMotion.haptic(AppHaptic.heavy);
      final size = MediaQuery.sizeOf(context);
      RewardFx.confetti(context, Offset(size.width / 2, size.height * .32),
          count: 60, duration: const Duration(milliseconds: 2800));
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _intro.dispose();
    _shine.dispose();
    super.dispose();
  }

  double _phase(double from, double len) =>
      ((_intro.value - from) / len).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final b = widget.boss;
    final motion = AppMotion.allowsDecorativeMotion(context);
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _intro, _shine]),
        builder: (context, _) {
          final pop =
              motion ? Curves.easeOutBack.transform(_phase(0, .35)) : 1.0;
          final crack = motion ? _phase(.25, .2) : 1.0;
          final count =
              motion ? Curves.easeOutCubic.transform(_phase(.35, .6)) : 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SlainRaysPainter(
                      angle: motion ? _spin.value * 2 * math.pi : 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: .7 + .3 * pop,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF280808),
                          border: Border.all(color: AppColors.red, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.red.withValues(alpha: .5),
                                blurRadius: 40),
                          ],
                        ),
                        child: ClipOval(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  .5, .4, .1, 0, 0, //
                                  .3, .6, .1, 0, 0,
                                  .3, .4, .3, 0, 0,
                                  0, 0, 0, 1, 0,
                                ]),
                                child: BossIcon(
                                    icon: b.icon, size: 112, emojiSize: 64),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                    painter: _PortraitCrack(grow: crack)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      b.isMini ? 'MINI-BOSS SLAIN' : 'BOSS SLAIN',
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFFFD9A8)],
                      ).createShader(r),
                      child: Text(
                        '${b.name} vanquished',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The path forward is yours.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (b.rewardXp > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(minWidth: 110),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.orange.withValues(alpha: .45)),
                        ),
                        child: Text(
                          '+${(b.rewardXp * count).round()} XP',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFD27A),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    _ClaimButton(
                      shine: motion ? _shine.value : -1,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final double shine;
  final VoidCallback onTap;
  const _ClaimButton({required this.shine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // The light sweep crosses in the first half, then rests.
    final x = shine < 0 ? null : (shine / .55).clamp(0.0, 1.0) * 1.9 - .6;
    return Semantics(
      button: true,
      label: 'Claim and continue',
      child: AppPressable(
        onTap: onTap,
        haptic: AppHaptic.light,
        child: Container(
          height: 50,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFD27A), Color(0xFFE8951F)],
            ),
            boxShadow: [
              BoxShadow(
                  color: AppColors.orange.withValues(alpha: .45),
                  blurRadius: 26,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (x != null && x < 1.3)
                Positioned.fill(
                  child: FractionalTranslation(
                    translation: Offset(x, 0),
                    child: const FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: .4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            Color(0xBFFFFFFF),
                            Colors.transparent
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              const Text(
                'CLAIM & CONTINUE',
                style: TextStyle(
                  color: Color(0xFF2A1A00),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlainRaysPainter extends CustomPainter {
  final double angle;
  _SlainRaysPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .5 - 110);
    final r = size.width * .75;
    final shader = RadialGradient(colors: [
      AppColors.red.withValues(alpha: .26),
      AppColors.red.withValues(alpha: 0),
    ]).createShader(Rect.fromCircle(center: c, radius: r));
    final p = Paint()..shader = shader;
    const n = 18;
    for (var i = 0; i < n; i++) {
      final a = angle + i * 2 * math.pi / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(
            Rect.fromCircle(center: c, radius: r), a, math.pi / n * .7, false)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_SlainRaysPainter old) => old.angle != angle;
}

class _PortraitCrack extends CustomPainter {
  final double grow;
  _PortraitCrack({required this.grow});

  @override
  void paint(Canvas canvas, Size size) {
    if (grow <= 0) return;
    final s = size.width / 132;
    final pts = [
      const Offset(66, 6),
      const Offset(58, 40),
      const Offset(72, 58),
      const Offset(54, 84),
      const Offset(64, 126),
    ];
    final path = Path()..moveTo(pts[0].dx * s, pts[0].dy * s);
    final n = ((pts.length - 1) * grow).ceil();
    for (var i = 1; i <= n; i++) {
      path.lineTo(pts[i].dx * s, pts[i].dy * s);
    }
    if (grow > .6) {
      path
        ..moveTo(72 * s, 58 * s)
        ..lineTo(104 * s, 64 * s)
        ..lineTo(124 * s, 50 * s);
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.white.withValues(alpha: .85));
  }

  @override
  bool shouldRepaint(_PortraitCrack old) => old.grow != grow;
}
