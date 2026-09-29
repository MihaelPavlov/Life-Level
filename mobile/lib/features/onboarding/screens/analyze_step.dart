import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/class_icons.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/onboarding_models.dart';
import '../onboarding_controller.dart';
import '../widgets/activity_visuals.dart';
import '../widgets/onboarding_ui.dart';

/// Step 5 — "Reading your training": each sport group races to its real
/// share, a dashed 40% line marks the threshold, and a verdict names the
/// detection state. Makes the class feel earned, not assigned.
class AnalyzeStep extends StatefulWidget {
  const AnalyzeStep({super.key});

  @override
  State<AnalyzeStep> createState() => _AnalyzeStepState();
}

class _AnalyzeStepState extends State<AnalyzeStep>
    with TickerProviderStateMixin {
  late final _race = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  late final _scan = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  late final Ticker _jitterTicker;
  Duration _elapsed = Duration.zero;

  ClassRecommendation? _rec;
  String? _error;
  bool _settled = false;
  final _winnerKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _jitterTicker = createTicker((d) => setState(() => _elapsed = d));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _jitterTicker.dispose();
    _race.dispose();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ctrl = OnboardingScope.read(context);
    setState(() => _error = null);
    try {
      final rec = await ctrl.loadRecommendation(force: true);
      if (!mounted) return;
      setState(() => _rec = rec);
      await _play();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn\'t read your training. Try again.');
      }
    }
  }

  Future<void> _play() async {
    final motion = onboardingMotion(context);
    if (!motion) {
      _race.value = 1;
      setState(() => _settled = true);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _scan.forward(from: 0);
    _jitterTicker.start();
    await _race.forward(from: 0);
    _jitterTicker.stop();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _settled = true);
    for (final k in _winners()) {
      final c = RewardFx.centerOf(_winnerKeys[k] ?? GlobalKey());
      if (c != null) {
        RewardFx.burst(context, c, classColorForName(k), count: 16, distance: 40);
      }
    }
  }

  List<String> _winners() {
    final rec = _rec;
    if (rec == null || rec.shares.isEmpty) return const [];
    final names = rec.shares.map((s) => s.className).toList();
    return switch (rec.state) {
      ClassDetectionState.clear || ClassDetectionState.devoted => names.take(1).toList(),
      ClassDetectionState.hybrid || ClassDetectionState.close => names.take(2).toList(),
      ClassDetectionState.multisport => names.take(3).toList(),
      _ => const [],
    };
  }

  (Color, String, String) _verdict(ClassRecommendation rec) {
    final s = rec.shares;
    String pct(int i) => i < s.length ? '${(s[i].share * 100).round()}%' : '0%';
    final top = s.isNotEmpty ? s[0].className : '';
    final second = s.length > 1 ? s[1].className : '';
    return switch (rec.state) {
      ClassDetectionState.clear => (
          AppColors.green,
          'One class stands out',
          '$top leads with ${pct(0)}, well past the 40% line.'
        ),
      ClassDetectionState.devoted => (
          AppColors.orange,
          'Almost all one sport',
          '${pct(0)} of your time is ${(rec.devotedActivityType ?? 'one sport').toLowerCase()}. That\'s devotion.'
        ),
      ClassDetectionState.multisport => (
          const Color(0xFF79C0FF),
          'Swim, bike and run',
          'Each of the three takes at least 15% of your time.'
        ),
      ClassDetectionState.hybrid || ClassDetectionState.close => (
          AppColors.purple,
          'Too close to call',
          '$top ${pct(0)} vs $second ${pct(1)}. You train both.'
        ),
      ClassDetectionState.balanced => (
          AppColors.blue,
          'No sport passes 40%',
          'Your training is spread out. That\'s the all-rounder.'
        ),
      ClassDetectionState.insufficient => (
          AppColors.textSecondary,
          'Not enough data yet',
          rec.workoutCount == 0
              ? 'No workouts to read yet. You\'ll pick your class.'
              : '${rec.workoutCount} workout${rec.workoutCount == 1 ? ' is' : 's is'} too few to read your style. You\'ll pick one.'
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final rec = _rec;
    final winners = _winners();

    return OnboardingScaffold(
      step: 2,
      glow: AppColors.blue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Entrance(
              child: OnboardingTitle(
                'Reading your training',
                subtitle: rec?.state == ClassDetectionState.insufficient
                    ? 'Only ${rec!.workoutCount} workouts in the last 30 days. Let\'s see what they say.'
                    : 'Share of your active minutes over the last 30 days, by the class each sport builds.',
              ),
            ),
            const SizedBox(height: 18),
            if (rec == null && _error == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.blue)),
              ),
            if (rec != null)
              Stack(
                children: [
                  Column(
                    children: [
                      for (var i = 0; i < rec.shares.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Entrance(
                            delay: Duration(milliseconds: 150 + i * 90),
                            child: _GroupBar(
                              share: rec.shares[i],
                              label: rec.state == ClassDetectionState.devoted &&
                                      i == 0 &&
                                      rec.devotedActivityType != null
                                  ? activityLabel(rec.devotedActivityType!)
                                  : classSportLabel(rec.shares[i].className),
                              iconKey: _winnerKeys.putIfAbsent(
                                  rec.shares[i].className, () => GlobalKey()),
                              progress: _race,
                              jitter: _settled
                                  ? 0
                                  : 14 *
                                      math.sin(_elapsed.inMilliseconds / 90 +
                                          i * 1.7),
                              state: !_settled
                                  ? _BarState.normal
                                  : winners.contains(rec.shares[i].className)
                                      ? _BarState.win
                                      : _BarState.dim,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _scan,
                        builder: (_, __) {
                          if (!_scan.isAnimating) return const SizedBox();
                          final t = _scan.value;
                          return Align(
                            alignment: Alignment(0, -1.4 + 2.8 * t),
                            child: Opacity(
                              opacity: math.sin(t * math.pi),
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.blue.withValues(alpha: 0),
                                      AppColors.blue.withValues(alpha: .18),
                                      AppColors.blue.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            if (rec != null && _settled) ...[
              const SizedBox(height: 6),
              Builder(builder: (_) {
                final (color, title, sub) = _verdict(rec);
                return Entrance.pop(
                  duration: const Duration(milliseconds: 420),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: .45)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: color, blurRadius: 10)
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(sub,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.45,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ),
          ],
        ),
      ),
      bottom: _error != null
          ? OnboardingButton(label: 'TRY AGAIN', onPressed: _load)
          : AnimatedOpacity(
              opacity: _settled ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_settled,
                child: OnboardingButton(
                  label: rec?.state == ClassDetectionState.insufficient
                      ? 'CHOOSE MY CLASS'
                      : 'REVEAL MY CLASS',
                  onPressed: ctrl.next,
                ),
              ),
            ),
    );
  }
}

enum _BarState { normal, win, dim }

class _GroupBar extends StatelessWidget {
  final ClassShare share;
  final String label;
  final GlobalKey iconKey;
  final Animation<double> progress;
  final double jitter;
  final _BarState state;

  const _GroupBar({
    required this.share,
    required this.label,
    required this.iconKey,
    required this.progress,
    required this.jitter,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final color = classColorForName(share.className);
    return AnimatedOpacity(
      opacity: state == _BarState.dim ? .4 : 1,
      duration: const Duration(milliseconds: 300),
      child: Row(
        children: [
          AnimatedContainer(
            key: iconKey,
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withValues(alpha: .4)),
              boxShadow: state == _BarState.win
                  ? [BoxShadow(color: color.withValues(alpha: .6), blurRadius: 18)]
                  : null,
            ),
            alignment: Alignment.center,
            child: AppIconImage(classSportIcon(share.className), size: 44),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: progress,
              builder: (_, __) {
                final e = Curves.easeOutCubic.transform(progress.value);
                final v = math.max(0.0, share.share * 100 * e + jitter * (1 - e));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                  text: label,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary)),
                              TextSpan(
                                  text: '  → ${share.className.toUpperCase()}',
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .5)),
                            ]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${v.round()}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: color)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (_, box) => SizedBox(
                        height: 8,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              width: box.maxWidth * (v / 100).clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                      color: color.withValues(alpha: .5),
                                      blurRadius: 8)
                                ],
                              ),
                            ),
                            Positioned(
                              left: box.maxWidth * .4,
                              top: -6,
                              bottom: -6,
                              child: CustomPaint(
                                size: const Size(1.5, 20),
                                painter: _DashPainter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: .35)
      ..strokeWidth = 1.5;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(0, math.min(y + 2, size.height)), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}
