import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../motion/app_motion.dart';
import 'boot_readiness.dart';

/// Full-screen loader shown over Home right after login or setup. It lifts
/// only when the data Home renders (profile, wallet, map, quests, unlocks)
/// has really loaded, so the player never sees half-built state.
class BootLoaderOverlay extends ConsumerStatefulWidget {
  final VoidCallback onFinished;

  /// Shortest time on screen, so a fast load doesn't flash.
  final Duration minDuration;

  /// When "Taking longer than usual · Try again" appears.
  final Duration slowAfter;

  /// When "Continue anyway" appears, so a flaky endpoint can't trap the player.
  final Duration escapeAfter;

  const BootLoaderOverlay({
    super.key,
    required this.onFinished,
    this.minDuration = const Duration(milliseconds: 800),
    this.slowAfter = const Duration(seconds: 8),
    this.escapeAfter = const Duration(seconds: 20),
  });

  @override
  ConsumerState<BootLoaderOverlay> createState() => _BootLoaderOverlayState();
}

class _BootLoaderOverlayState extends ConsumerState<BootLoaderOverlay>
    with TickerProviderStateMixin {
  late final _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  late final _exit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
  final _timers = <Timer>[];
  bool _minElapsed = false;
  bool _slow = false;
  bool _canEscape = false;
  bool _ready = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    bootLoaderShowing = true;
    _timers
      ..add(Timer(widget.minDuration, () => _set(() => _minElapsed = true)))
      ..add(Timer(widget.slowAfter, () => _set(() => _slow = true)))
      ..add(Timer(widget.escapeAfter, () => _set(() => _canEscape = true)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.allowsDecorativeMotion(context)) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _pulse.dispose();
    _exit.dispose();
    bootLoaderShowing = false;
    super.dispose();
  }

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  /// "Ready, hero" for a beat, then fade out and hand over to Home.
  Future<void> _finish({bool hold = true}) async {
    if (_finishing) return;
    _finishing = true;
    _set(() => _ready = true);
    final motion = AppMotion.allowsDecorativeMotion(context);
    if (hold) {
      await Future<void>.delayed(Duration(milliseconds: motion ? 450 : 150));
    }
    if (!mounted) return;
    await _exit.animateTo(1,
        duration: motion ? const Duration(milliseconds: 350) : Duration.zero);
    bootLoaderShowing = false;
    if (mounted) widget.onFinished();
  }

  void _retry(BootReadiness r) {
    for (final step in BootStep.values) {
      if (r[step] != BootStepState.done) retryBootStep(ref, step);
    }
    _set(() => _slow = false);
    _timers.add(Timer(widget.slowAfter, () => _set(() => _slow = true)));
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(bootReadinessProvider);
    if (r.allDone && _minElapsed && !_finishing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
    final trouble = !r.allDone && (_slow || r.anyFailed);

    // Opaque: swallows taps meant for Home underneath, while the loader's
    // own buttons still work.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: AnimatedBuilder(
        animation: _exit,
        builder: (context, child) =>
            Opacity(opacity: 1 - _exit.value, child: child),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -.4),
              radius: .9,
              colors: [Color(0xFF0E1A2E), AppColors.background],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Scales down on short screens rather than overflowing.
                Flexible(
                  flex: 20,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LogoRing(
                          fraction: r.doneCount / BootStep.values.length,
                          ready: r.allDone,
                          pulse: _pulse,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'LIFE LEVEL',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _ready ? 'Ready, hero' : 'Preparing your world',
                            key: ValueKey(_ready),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _ready
                                  ? const Color(0xFF7EE787)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 250,
                          child: Column(
                            children: [
                              for (final step in BootStep.values)
                                _StepRow(
                                  label: step.label,
                                  state: r[step],
                                  last: step == BootStep.values.last,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 300,
                          height: 160,
                          child: AnimatedOpacity(
                            opacity: trouble ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: IgnorePointer(
                              ignoring: !trouble,
                              child: Column(
                                children: [
                                  Text(
                                    r.anyFailed
                                        ? 'Something didn\'t load.'
                                        : 'Taking longer than usual.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _retry(r),
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 18),
                                    label: const Text('Try again'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF8CC0FF),
                                      backgroundColor:
                                          AppColors.blue.withValues(alpha: .12),
                                      side: BorderSide(
                                          color: AppColors.blue
                                              .withValues(alpha: .5)),
                                      minimumSize: const Size(0, 44),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  if (_canEscape)
                                    TextButton(
                                      onPressed: () => _finish(hold: false),
                                      child: const Text(
                                        'Continue anyway',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Train in the real world. Level up in this one.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
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
}

/// The app logo inside a progress ring that fills as rows finish, with a
/// gentle pulse and a light sweep across the logo.
class _LogoRing extends StatelessWidget {
  final double fraction;
  final bool ready;
  final AnimationController pulse;
  const _LogoRing(
      {required this.fraction, required this.ready, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final color = ready ? AppColors.green : AppColors.blue;
    return SizedBox(
      width: 184,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              size: const Size(184, 184),
              painter: _RingPainter(progress: v, color: color),
            ),
          ),
          AnimatedBuilder(
            animation: pulse,
            builder: (_, child) {
              final t = pulse.value;
              final s = 1 + .04 * math.sin(t * 2 * math.pi);
              return Transform.scale(
                scale: pulse.isAnimating ? s : 1,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: ready ? .55 : .3),
                        blurRadius: ready ? 70 : 50,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        child!,
                        if (pulse.isAnimating && t < .55)
                          Positioned(
                            top: -40,
                            bottom: -40,
                            left: -60 + (t / .55) * 240,
                            width: 44,
                            child: Transform.rotate(
                              angle: .35,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: .5),
                                    Colors.white.withValues(alpha: 0),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Image.asset(AppIcons.appLogo,
                width: 120, height: 120, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = AppColors.blue.withValues(alpha: .15),
    );
    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.color != color;
}

class _StepRow extends StatelessWidget {
  final String label;
  final BootStepState state;
  final bool last;
  const _StepRow(
      {required this.label, required this.state, required this.last});

  @override
  Widget build(BuildContext context) {
    final done = state == BootStepState.done;
    final failed = state == BootStepState.failed;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                    color: AppColors.textPrimary.withValues(alpha: .06))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: done
                  ? const _Badge(
                      key: ValueKey('done'),
                      color: AppColors.green,
                      icon: Icons.check_rounded)
                  : failed
                      ? const _Badge(
                          key: ValueKey('failed'),
                          color: AppColors.red,
                          icon: Icons.priority_high_rounded)
                      : const CircularProgressIndicator(
                          key: ValueKey('loading'),
                          strokeWidth: 2,
                          color: AppColors.blue,
                          backgroundColor: Color(0x404F9EFF),
                        ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: done || failed
                    ? AppColors.textPrimary
                    : const Color(0xFF6E7681),
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _Badge({super.key, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 13, color: AppColors.background),
    );
  }
}
