import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';

/// How far Home has to be pulled before letting go checks for workouts.
const kPullToImportThreshold = 96.0;

/// Wraps Home's scroll view: pulling past the top fills a rune, releasing
/// when it is full calls [onTrigger]. While [busy] the rune stays up and
/// spins.
///
/// The child must use [PullToImport.physics] so it can overscroll on Android
/// too (Clamping physics never reports a pull past the top).
class PullToImport extends StatefulWidget {
  final Widget child;
  final int pendingCount;
  final bool busy;
  final Future<void> Function() onTrigger;

  /// Distance from the top of this widget to where the rune rests.
  final double topInset;

  const PullToImport({
    super.key,
    required this.child,
    required this.pendingCount,
    required this.busy,
    required this.onTrigger,
    this.topInset = 0,
  });

  static const physics =
      BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  State<PullToImport> createState() => _PullToImportState();
}

class _PullToImportState extends State<PullToImport>
    with SingleTickerProviderStateMixin {
  double _pull = 0;
  bool _armed = false;
  bool _fired = false;
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(covariant PullToImport old) {
    super.didUpdateWidget(old);
    if (widget.busy && !_spin.isAnimating) {
      if (AppMotion.allowsDecorativeMotion(context)) _spin.repeat();
    } else if (!widget.busy && _spin.isAnimating) {
      _spin.stop();
      _spin.reset();
    }
    if (!widget.busy && old.busy) _fired = false;
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification) {
      final over = math.max(0.0, n.metrics.minScrollExtent - n.metrics.pixels);
      if (n.dragDetails != null) {
        final armed = over >= kPullToImportThreshold;
        if (armed && !_armed) AppMotion.haptic(AppHaptic.selection);
        setState(() {
          _pull = over;
          _armed = armed;
        });
      } else {
        // Finger lifted: the list springs back. Fire once if it was full.
        if (_armed && !_fired && !widget.busy) {
          _fired = true;
          AppMotion.haptic(AppHaptic.light);
          widget.onTrigger();
        }
        setState(() {
          _pull = over;
          _armed = false;
        });
      }
    } else if (n is ScrollEndNotification) {
      if (_pull != 0 || _armed) {
        setState(() {
          _pull = 0;
          _armed = false;
        });
      }
    }
    return false;
  }

  String get _label {
    if (widget.busy) return 'Checking your workouts…';
    final n = widget.pendingCount;
    if (n > 0) {
      return _armed
          ? 'Release to import'
          : 'Pull to import $n workout${n == 1 ? '' : 's'}';
    }
    return _armed ? 'Release to check' : 'Pull to sync';
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.busy ? 1.0 : (_pull / kPullToImportThreshold).clamp(0.0, 1.0);
    final visible = widget.busy || _pull > 6;
    // The rune rides down with the finger, then rests while busy.
    final travel = widget.busy ? 40.0 : math.min(_pull, 130.0) * .55;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: widget.topInset - 30 + travel,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Semantics(
                liveRegion: true,
                label: visible ? _label : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Rune(
                      progress: progress,
                      armed: _armed,
                      busy: widget.busy,
                      spin: _spin,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xCC080E14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: widget.pendingCount > 0 && !widget.busy
                              ? AppColors.orange
                              : const Color(0xFF8CC0FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Rune extends StatelessWidget {
  final double progress;
  final bool armed;
  final bool busy;
  final Animation<double> spin;
  const _Rune({
    required this.progress,
    required this.armed,
    required this.busy,
    required this.spin,
  });

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    return AnimatedScale(
      scale: armed ? 1.1 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-.25, -.4),
            colors: [Color(0xFF1B2A44), Color(0xFF0A111C)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: armed || busy ? .6 : .25),
              blurRadius: armed || busy ? 18 : 10,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: spin,
              child: CustomPaint(
                size: const Size(size, size),
                painter: _RingPainter(busy ? .3 : progress),
              ),
            ),
            Image.asset(AppIcons.mapDestination, width: 30, height: 30),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    final r = rect.deflate(4);
    canvas.drawArc(
      r,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = AppColors.blue.withValues(alpha: .2),
    );
    if (value <= 0) return;
    canvas.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.blue,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
