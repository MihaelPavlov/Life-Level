import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import 'tour_bubble_tail.dart';
import 'tour_step.dart';
import 'tour_target.dart';

enum TourOutcome {
  /// Every stop was shown.
  finished,

  /// The player tapped Skip.
  skipped,

  /// A target never showed up or disappeared (the player navigated away).
  aborted,
}

/// Spotlight tours: dims the screen, cuts a hole around one real widget at a
/// time and explains it in a bubble. Stops that ask for a tap let the tap
/// through the hole to the real widget, so the tour ends by doing the
/// feature's main action for real.
///
/// Drawn on the root overlay, so it also covers pushed routes and sheets.
abstract final class FeatureTour {
  static bool _running = false;
  static bool get isRunning => _running;

  /// Runs [steps]. [onComplete] is called once the tour is over, whatever
  /// the outcome, and returns the XP it paid (shown on the "explored" card,
  /// which only appears when the tour was [TourOutcome.finished]).
  static Future<TourOutcome> run(
    BuildContext context, {
    required String name,
    required Color color,
    required List<TourStep> steps,
    Future<int> Function(TourOutcome outcome)? onComplete,
  }) async {
    if (_running || steps.isEmpty) return TourOutcome.aborted;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return TourOutcome.aborted;
    _running = true;

    final c = _TourController(color: color, total: steps.length);
    final entry = OverlayEntry(builder: (_) => _TourLayer(controller: c));
    overlay.insert(entry);
    void onTap(String id) => c.tapped(id);
    TourTargets.addTapListener(onTap);

    var outcome = TourOutcome.finished;
    try {
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        c.hide();
        // A stop whose widget isn't there (nothing to claim, no continue
        // card…) is skipped; the tour only fails if no stop ever showed.
        final wait = c.started
            ? const Duration(milliseconds: 1200)
            : const Duration(milliseconds: 2500);
        if (!await _reveal(step.targetId, wait)) continue;
        final tapMode = step.isTap && TourTargets.isEnabled(step.targetId);
        final answer = await c.show(i, step, tapMode: tapMode);
        if (answer == _Answer.skip) {
          outcome = TourOutcome.skipped;
          break;
        }
        if (answer == _Answer.lost) {
          outcome = TourOutcome.aborted;
          break;
        }
        if (answer == _Answer.tap) {
          // Let the real action start before the next stop or the card.
          await Future<void>.delayed(const Duration(milliseconds: 700));
        }
      }
    } finally {
      TourTargets.removeTapListener(onTap);
    }
    if (!c.started) outcome = TourOutcome.aborted;

    c.hide();
    var xp = 0;
    try {
      xp = await (onComplete?.call(outcome) ?? Future.value(0));
    } catch (_) {
      xp = 0;
    }
    if (outcome == TourOutcome.finished && entry.mounted) {
      c.explore(name, xp);
      if (context.mounted) {
        final size = MediaQuery.sizeOf(context);
        RewardFx.confetti(context, Offset(size.width / 2, size.height * .46),
            count: 40);
      }
      await Future<void>.delayed(const Duration(milliseconds: 1700));
    }
    if (entry.mounted) entry.remove();
    c.dispose();
    _running = false;
    return outcome;
  }

  /// Waits for the target to be laid out, then scrolls it into view.
  static Future<bool> _reveal(String id, Duration wait) async {
    const tick = Duration(milliseconds: 16);
    var waited = Duration.zero;
    while (TourTargets.rectOf(id) == null) {
      if (waited >= wait) return false;
      await Future<void>.delayed(tick);
      waited += tick;
    }
    final ctx = TourTargets.contextOf(id);
    final rect = TourTargets.rectOf(id);
    if (ctx != null && rect != null && ctx.mounted) {
      final screen = MediaQuery.sizeOf(ctx);
      final visible = rect.top >= 90 && rect.bottom <= screen.height - 150;
      if (!visible && Scrollable.maybeOf(ctx) != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: .3,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
    return TourTargets.rectOf(id) != null;
  }
}

enum _Answer { next, skip, tap, lost }

class _TourController extends ChangeNotifier {
  final Color color;
  final int total;

  _TourController({required this.color, required this.total});

  int index = 0;
  TourStep? step;

  /// False until the first stop is on screen, so a tour whose target never
  /// shows up leaves no trace.
  bool started = false;
  bool tapMode = false;
  String? exploredName;
  int exploredXp = 0;
  Completer<_Answer>? _pending;

  Color get stepColor => step?.color ?? color;

  Future<_Answer> show(int i, TourStep s, {required bool tapMode}) {
    index = i;
    step = s;
    started = true;
    this.tapMode = tapMode;
    _pending = Completer<_Answer>();
    notifyListeners();
    return _pending!.future;
  }

  void hide() {
    step = null;
    notifyListeners();
  }

  void answer(_Answer a) {
    final p = _pending;
    if (p != null && !p.isCompleted) p.complete(a);
  }

  void tapped(String id) {
    if (tapMode && step?.targetId == id) answer(_Answer.tap);
  }

  void explore(String name, int xp) {
    exploredName = name;
    exploredXp = xp;
    notifyListeners();
  }
}

class _TourLayer extends StatefulWidget {
  final _TourController controller;
  const _TourLayer({required this.controller});

  @override
  State<_TourLayer> createState() => _TourLayerState();
}

class _TourLayerState extends State<_TourLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Rect? _shown; // eased toward the target every frame
  Duration _missingFor = Duration.zero;
  Duration _last = Duration.zero;
  double _pulse = 0;

  _TourController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    c.addListener(_onChange);
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    _ticker.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _tick(Duration now) {
    final dt = now - _last;
    _last = now;
    _pulse = (now.inMilliseconds % 1600) / 1600;
    final step = c.step;
    if (step == null) {
      _missingFor = Duration.zero;
      setState(() {});
      return;
    }
    final target = TourTargets.rectOf(step.targetId);
    if (target == null) {
      _missingFor += dt;
      if (_missingFor > const Duration(milliseconds: 1200)) {
        c.answer(_Answer.lost);
      }
      return;
    }
    _missingFor = Duration.zero;
    final origin = _origin();
    final local = target.shift(-origin).inflate(step.pad);
    final full = AppMotion.isFull(context);
    _shown = _shown == null || !full ? local : Rect.lerp(_shown, local, .28);
    setState(() {});
  }

  Offset _origin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final step = c.step;
    final size = MediaQuery.sizeOf(context);
    final hole = step == null ? null : _shown;
    final color = c.stepColor;
    if (!c.started && c.exploredName == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: c.exploredName != null ? .55 : 1,
              duration: const Duration(milliseconds: 250),
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: hole,
                  radius: step?.radius ?? 18,
                  circular: step?.circular ?? false,
                  color: color,
                  pulse: _pulse,
                ),
              ),
            ),
          ),
        ),
        // Blocks every touch except, on a tap stop, the ones in the hole.
        Positioned.fill(
          child: _HoleBarrier(
            hole: step != null && c.tapMode && hole != null
                ? hole.shift(_origin())
                : null,
          ),
        ),
        if (step != null && hole != null)
          _bubble(context, step, hole, size, color),
        if (c.exploredName != null)
          Center(
              child: _ExploredCard(
                  name: c.exploredName!, xp: c.exploredXp, color: c.color)),
      ],
    );
  }

  Widget _bubble(
      BuildContext context, TourStep step, Rect hole, Size size, Color color) {
    const bubbleH = 170.0; // estimate for placement; the bubble sizes itself
    final below = hole.center.dy < size.height * .51;
    final top =
        below ? math.min(hole.bottom + 14, size.height - bubbleH - 24) : null;
    final bottom = below
        ? null
        : math.min(size.height - hole.top + 14, size.height - bubbleH - 44);
    final tailX = (hole.center.dx - 16 - 8).clamp(18.0, size.width - 32 - 34);

    return Positioned(
      left: 16,
      right: 16,
      top: top,
      bottom: bottom,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(c.index),
        tween: Tween(begin: 0, end: 1),
        duration:
            AppMotion.duration(context, const Duration(milliseconds: 320)),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
              offset: Offset(0, (1 - t) * 10), child: child),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (below)
              Padding(
                padding: EdgeInsets.only(left: tailX),
                child: TourBubbleTail(
                  direction: TailDirection.up,
                  accentColor: color,
                  fillColor: AppColors.surface,
                ),
              ),
            _Bubble(
              step: step,
              color: color,
              index: c.index,
              total: c.total,
              tapMode: c.tapMode,
              onNext: () => c.answer(_Answer.next),
              onSkip: () => c.answer(_Answer.skip),
            ),
            if (!below)
              Padding(
                padding: EdgeInsets.only(left: tailX),
                child: TourBubbleTail(
                  direction: TailDirection.down,
                  accentColor: color,
                  fillColor: AppColors.surface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final TourStep step;
  final Color color;
  final int index;
  final int total;
  final bool tapMode;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Bubble({
    required this.step,
    required this.color,
    required this.index,
    required this.total,
    required this.tapMode,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final last = index == total - 1;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .5)),
          boxShadow: [
            const BoxShadow(
                color: Color(0x99000000),
                blurRadius: 40,
                offset: Offset(0, 18)),
            BoxShadow(color: color.withValues(alpha: .2), blurRadius: 30),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: .4)),
                  ),
                  child: AppIconImage(step.icon, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.eyebrow,
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: color)),
                      const SizedBox(height: 2),
                      Text(step.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(children: boldSpans(step.body)),
              style: const TextStyle(
                  fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var k = 0; k < total; k++)
                  Container(
                    margin: const EdgeInsets.only(right: 5),
                    width: k == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: k < index
                          ? AppColors.green
                          : k == index
                              ? color
                              : AppColors.surfaceElevated,
                      border: k > index
                          ? Border.all(color: AppColors.border)
                          : null,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(44, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Skip',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                if (tapMode)
                  _TapHint(label: step.tapLabel!, color: color)
                else
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(last ? 'GOT IT' : 'NEXT',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Splits `**bold**` markers into spans.
List<TextSpan> boldSpans(String text) {
  final parts = text.split('**');
  return [
    for (var i = 0; i < parts.length; i++)
      TextSpan(
        text: parts[i],
        style: i.isOdd
            ? const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)
            : null,
      ),
  ];
}

class _TapHint extends StatefulWidget {
  final String label;
  final Color color;
  const _TapHint({required this.label, required this.color});

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween(begin: .2, end: 1.0).animate(_blink),
          child: Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text(widget.label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .4,
                color: widget.color)),
      ],
    );
  }
}

class _ExploredCard extends StatelessWidget {
  final String name;
  final int xp;
  final Color color;
  const _ExploredCard(
      {required this.name, required this.xp, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .8, end: 1),
      duration: AppMotion.duration(context, const Duration(milliseconds: 400)),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(minWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: .5)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .3), blurRadius: 40),
              const BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 50,
                  offset: Offset(0, 20)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FEATURE EXPLORED',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      color: color)),
              const SizedBox(height: 4),
              Text('$name explored',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
              if (xp > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: AppColors.orange.withValues(alpha: .35)),
                  ),
                  child: Text('+$xp XP',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.orange)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final double radius;
  final bool circular;
  final Color color;
  final double pulse;

  _SpotlightPainter({
    required this.hole,
    required this.radius,
    required this.circular,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0xBD02050A);
    final h = hole;
    if (h == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }
    final shape = circular
        ? (Path()
          ..addOval(
              Rect.fromCircle(center: h.center, radius: h.longestSide / 2)))
        : (Path()
          ..addRRect(RRect.fromRectAndRadius(h, Radius.circular(radius))));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addPath(shape, Offset.zero);
    canvas.drawPath(path, dim);

    // Breathing ring just outside the hole.
    final t = math.sin(pulse * math.pi);
    final grow = 5 + 4 * t;
    final ringRect = h.inflate(grow);
    final ring = circular
        ? (Path()
          ..addOval(Rect.fromCircle(
              center: h.center, radius: ringRect.longestSide / 2)))
        : (Path()
          ..addRRect(RRect.fromRectAndRadius(
              ringRect, Radius.circular(radius + grow))));
    canvas.drawPath(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = color.withValues(alpha: .18 + .12 * (1 - t))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawPath(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 1 - .45 * t));
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.hole != hole ||
      old.pulse != pulse ||
      old.color != color ||
      old.radius != radius ||
      old.circular != circular;
}

/// Absorbs every touch except those inside [hole] (global coordinates),
/// which fall through to the app underneath.
class _HoleBarrier extends LeafRenderObjectWidget {
  final Rect? hole;
  const _HoleBarrier({required this.hole});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHoleBarrier()..hole = hole;

  @override
  void updateRenderObject(BuildContext context, _RenderHoleBarrier r) =>
      r.hole = hole;
}

class _RenderHoleBarrier extends RenderBox {
  Rect? hole;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    final h = hole;
    if (h != null && h.contains(localToGlobal(position))) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
