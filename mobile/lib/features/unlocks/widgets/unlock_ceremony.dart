import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/unlock_catalog.dart';

/// "NEW FEATURE UNLOCKED": the padlock shakes and shatters, the feature's
/// icon lights up and the player picks Show me or Later.
/// [queue] is every feature in this moment (at most two) and [index] which
/// one this is; with more than one the ceremony shows an "Unlock 1 of 2"
/// counter. Resolves to true for Show me.
Future<bool> showUnlockCeremony(BuildContext context, UnlockMeta meta,
    {List<UnlockMeta> queue = const [], int index = 0}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration:
        AppMotion.duration(context, const Duration(milliseconds: 300)),
    pageBuilder: (_, __, ___) =>
        UnlockCeremony(meta: meta, queue: queue, index: index),
    transitionBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
  );
  return result ?? false;
}

/// The hand-off between two ceremonies of one moment: "1 MORE UNLOCK", the
/// next feature's silhouette and a bar that fills, then it closes itself.
Future<void> showUnlockBridge(BuildContext context, UnlockMeta next,
    {int remaining = 1}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: const Color(0x8C02050A),
    transitionDuration:
        AppMotion.duration(context, const Duration(milliseconds: 280)),
    pageBuilder: (_, __, ___) =>
        _UnlockBridge(next: next, remaining: remaining),
    transitionBuilder: (_, a, __, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
          scale: Tween(begin: .92, end: 1.0)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
          child: child),
    ),
  );
}

class _UnlockBridge extends StatefulWidget {
  final UnlockMeta next;
  final int remaining;
  const _UnlockBridge({required this.next, required this.remaining});

  @override
  State<_UnlockBridge> createState() => _UnlockBridgeState();
}

class _UnlockBridgeState extends State<_UnlockBridge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (AppMotion.isFull(context)) {
        await _fill.forward();
      } else {
        _fill.value = 1;
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.remaining;
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 250,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.orange.withValues(alpha: .45)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.orange.withValues(alpha: .18),
                  blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(n == 1 ? '1 MORE UNLOCK' : '$n MORE UNLOCKS',
                  style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: AppColors.orange)),
              const SizedBox(height: 10),
              _Silhouette(icon: widget.next.icon, size: 56),
              const SizedBox(height: 6),
              Text(widget.next.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: AnimatedBuilder(
                  animation: _fill,
                  builder: (_, __) => LinearProgressIndicator(
                    value: _fill.value,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A feature icon drawn as a grey shape (not unlocked yet).
class _Silhouette extends StatelessWidget {
  final String icon;
  final double size;
  const _Silhouette({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) => ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0, 0, 0, 0, 89, //
          0, 0, 0, 0, 89,
          0, 0, 0, 0, 89,
          0, 0, 0, .6, 0,
        ]),
        child: AppIconImage(icon, size: size),
      );
}

class UnlockCeremony extends StatefulWidget {
  final UnlockMeta meta;

  /// Every feature opening in this moment, in order; empty for a lone unlock.
  final List<UnlockMeta> queue;
  final int index;

  const UnlockCeremony(
      {super.key, required this.meta, this.queue = const [], this.index = 0});

  @override
  State<UnlockCeremony> createState() => _UnlockCeremonyState();
}

class _UnlockCeremonyState extends State<UnlockCeremony>
    with TickerProviderStateMixin {
  // 0.00–0.18 settle · 0.18–0.48 shake · 0.48–0.57 shackle · 0.57 shatter
  // · 0.57–0.80 reveal · 0.70–1.00 text and buttons.
  late final AnimationController _seq = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000));
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 22));
  final _orbKey = GlobalKey();
  bool _shattered = false;

  UnlockMeta get m => widget.meta;

  @override
  void initState() {
    super.initState();
    _seq.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.isFull(context)) {
        _spin.repeat();
        _seq.forward();
      } else {
        _shattered = true;
        _seq.value = 1;
      }
    });
  }

  void _onTick() {
    if (!_shattered && _seq.value >= .57) {
      _shattered = true;
      final at = RewardFx.centerOf(_orbKey);
      if (at != null) {
        AppMotion.haptic(AppHaptic.light);
        RewardFx.burst(context, at, Colors.white,
            count: 18, distance: 90, size: 4);
        RewardFx.ring(context, at, Colors.white, maxRadius: 90);
        RewardFx.burst(context, at, m.color, count: 24, distance: 110);
        RewardFx.confetti(context, at, count: 50);
      }
    }
  }

  @override
  void dispose() {
    _seq.dispose();
    _spin.dispose();
    super.dispose();
  }

  double _span(double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((_seq.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
      child: Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xB802050A),
            gradient: RadialGradient(
              center: const Alignment(0, -.16),
              radius: .75,
              colors: [m.color.withValues(alpha: .24), const Color(0x0002050A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedBuilder(
                animation: Listenable.merge([_seq, _spin]),
                builder: (context, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.queue.length > 1) ...[
                      _queueCounter(),
                      const SizedBox(height: 28),
                    ],
                    const Text('NEW FEATURE UNLOCKED',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.4,
                            color: AppColors.orange)),
                    const SizedBox(height: 14),
                    _orb(),
                    const SizedBox(height: 6),
                    _reveal(
                        0,
                        Text(m.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary))),
                    const SizedBox(height: 8),
                    _reveal(
                        1,
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(m.line,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textSecondary)),
                        )),
                    const SizedBox(height: 12),
                    _reveal(2, _perk()),
                    const SizedBox(height: 22),
                    _reveal(3, _buttons()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orb() {
    final shake = _span(.18, .48);
    final angle = math.sin(shake * math.pi * 5) * .2 * (1 - shake);
    final shackle = _span(.48, .57, Curves.easeOut);
    final lockOut = _span(.57, .70, Curves.easeOut);
    final reveal = _span(.57, .80, Curves.elasticOut);
    final raysIn = _span(.57, .85);
    final silhouette = !_shattered;

    return SizedBox(
      key: _orbKey,
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                m.color.withValues(alpha: .38),
                m.color.withValues(alpha: 0),
              ], stops: const [
                0,
                .68
              ]),
            ),
          ),
          if (raysIn > 0)
            Positioned(
              left: -40,
              top: -40,
              right: -40,
              bottom: -40,
              child: Opacity(
                opacity: .22 * raysIn,
                child: Transform.rotate(
                  angle: _spin.value * 2 * math.pi,
                  child: CustomPaint(painter: _RaysPainter(m.color)),
                ),
              ),
            ),
          Transform.rotate(
            angle: -_spin.value * 2 * math.pi * 1.4,
            child: Container(
              margin: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: m.color.withValues(alpha: .4), width: 1.5),
              ),
            ),
          ),
          Transform.scale(
            scale: silhouette ? .85 : .85 + .15 * reveal,
            child: silhouette
                ? ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      0, 0, 0, 0, 89, //
                      0, 0, 0, 0, 89,
                      0, 0, 0, 0, 89,
                      0, 0, 0, .6, 0,
                    ]),
                    child: AppIconImage(m.icon, size: 64),
                  )
                : AppIconImage(m.icon, size: 64),
          ),
          if (lockOut < 1)
            Opacity(
              opacity: 1 - lockOut,
              child: Transform.scale(
                scale: 1 + .6 * lockOut,
                child: Transform.rotate(
                  angle: angle,
                  child: SizedBox(
                    width: 64,
                    height: 78,
                    child: CustomPaint(painter: _PadlockPainter(shackle)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// "UNLOCK 1 OF 2" and one tile per feature: done ones carry a check, the
  /// current one glows in its colour, later ones are still grey.
  Widget _queueCounter() {
    final q = widget.queue;
    final pop = _span(.57, .75, Curves.elasticOut);
    return Column(
      children: [
        Text('UNLOCK ${widget.index + 1} OF ${q.length}',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < q.length; i++) ...[
              if (i > 0)
                Container(
                  width: 12,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(1)),
                ),
              Transform.scale(
                scale: i == widget.index ? 1 + .25 * math.sin(pop * math.pi) : 1,
                child: _queueTile(q[i], i),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _queueTile(UnlockMeta meta, int i) {
    final done = i < widget.index, current = i == widget.index;
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1017),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: current
                    ? meta.color
                    : done
                        ? AppColors.green.withValues(alpha: .6)
                        : AppColors.border,
                width: current ? 2 : 1,
              ),
              boxShadow: current
                  ? [
                      BoxShadow(
                          color: meta.color.withValues(alpha: .4),
                          blurRadius: 12)
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: done || current
                ? AppIconImage(meta.icon, size: 22)
                : _Silhouette(icon: meta.icon, size: 22),
          ),
          if (done)
            Positioned(
              right: -5,
              bottom: -5,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                    color: AppColors.green, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check_rounded,
                    size: 10, color: Color(0xFF040810)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _perk() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconImage(m.perkIcon, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(m.perk,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ],
        ),
      );

  Widget _buttons() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _seq.value < .7
                  ? null
                  : () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: m.color,
                disabledBackgroundColor: m.color,
                foregroundColor: Colors.white,
                shadowColor: m.color.withValues(alpha: .35),
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('SHOW ME ${m.name.toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed:
                _seq.value < .7 ? null : () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size.fromHeight(44)),
            child: Text(_laterLabel,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      );

  String get _laterLabel {
    final left = widget.queue.length - widget.index - 1;
    if (left <= 0) return 'Later · tour runs on first visit';
    return 'Later · $left more unlock${left == 1 ? '' : 's'} waiting';
  }

  /// Staggered fade-up for the text and buttons after the lock breaks.
  Widget _reveal(int i, Widget child) {
    final t = _span(.70 + i * .045, .88 + i * .045, Curves.easeOutCubic);
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
    );
  }
}

class _PadlockPainter extends CustomPainter {
  /// 0 closed … 1 shackle popped open.
  final double open;
  _PadlockPainter(this.open);

  @override
  void paint(Canvas canvas, Size size) {
    const fg = AppColors.textPrimary;
    final shackle = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.save();
    // The shackle lifts and swings open around its right leg.
    canvas.translate(48, 34);
    canvas.rotate(-.32 * open);
    canvas.translate(-48, -34 - 10 * open);
    canvas.drawPath(
      Path()
        ..moveTo(16, 34)
        ..lineTo(16, 22)
        ..arcToPoint(const Offset(48, 22), radius: const Radius.circular(16))
        ..lineTo(48, 34),
      shackle,
    );
    canvas.restore();
    final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 32, 52, 40), const Radius.circular(10));
    canvas.drawRRect(body, Paint()..color = AppColors.surfaceElevated);
    canvas.drawRRect(
        body,
        Paint()
          ..color = fg
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(const Offset(32, 50), 5, Paint()..color = fg);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(30, 52, 4, 11), const Radius.circular(2)),
        Paint()..color = fg);
  }

  @override
  bool shouldRepaint(covariant _PadlockPainter old) => old.open != open;
}

class _RaysPainter extends CustomPainter {
  final Color color;
  _RaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
        stops: const [.3, .45, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    const n = 15;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi;
      const w = 5 / 360 * 2 * math.pi;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + r * math.cos(a), c.dy + r * math.sin(a))
          ..lineTo(c.dx + r * math.cos(a + w), c.dy + r * math.sin(a + w))
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.color != color;
}
