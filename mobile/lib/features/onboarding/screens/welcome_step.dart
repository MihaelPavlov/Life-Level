import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_ui.dart';

/// Step 1 — shows the payoff first: past workouts turning into XP.
class WelcomeStep extends StatefulWidget {
  const WelcomeStep({super.key});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep> {
  static const _cards = [
    (AppIcons.activityRunning, 'Long run · 14.1 km', 'Sep 6', '+282 XP', -5.0, .55),
    (AppIcons.activityGym, 'Upper body · 52 min', 'Sep 18', '+140 XP', 3.5, .8),
    (AppIcons.activityCycling, 'Evening ride · 31 km', 'Yesterday', '+310 XP', 0.0, 1.0),
  ];
  final _chipKeys = List.generate(3, (_) => GlobalKey());
  final _pulse = ValueNotifier<int>(-1);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1300), _sparkChips);
  }

  Future<void> _sparkChips() async {
    for (var i = 0; i < _chipKeys.length; i++) {
      if (!mounted) return;
      _pulse.value = i;
      final c = RewardFx.centerOf(_chipKeys[i]);
      if (c != null) RewardFx.burst(context, c, AppColors.orange, count: 10);
      await Future.delayed(const Duration(milliseconds: 260));
    }
    if (mounted) _pulse.value = -1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    return OnboardingScaffold(
      step: 0,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 290,
            child: Stack(
              children: [
                for (var i = 0; i < _cards.length; i++)
                  Positioned(
                    top: [16.0, 100.0, 186.0][i],
                    left: [0.0, 36.0, 8.0][i],
                    right: [44.0, 0.0, 0.0][i],
                    child: Entrance(
                      delay: Duration(milliseconds: 150 + i * 160),
                      duration: const Duration(milliseconds: 700),
                      from: const Offset(0, 40),
                      fromScale: .9,
                      curve: Curves.easeOutBack,
                      child: _Bob(
                        phase: i * 1.3,
                        child: Transform.rotate(
                          angle: _cards[i].$5 * math.pi / 180,
                          child: Opacity(
                            opacity: _cards[i].$6,
                            child: _WorkoutCard(
                              icon: _cards[i].$1,
                              title: _cards[i].$2,
                              date: _cards[i].$3,
                              xp: _cards[i].$4,
                              hot: i == 2,
                              chipKey: _chipKeys[i],
                              pulse: _pulse,
                              index: i,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Entrance(
            delay: Duration(milliseconds: 600),
            from: Offset(0, 24),
            child: Text(
              'Your last 30 days',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                height: 1.12,
                letterSpacing: -.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Entrance(
            delay: const Duration(milliseconds: 720),
            from: const Offset(0, 24),
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [AppColors.blue, AppColors.purple],
              ).createShader(r),
              child: const Text(
                'already count.',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                  letterSpacing: -.6,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Entrance(
            delay: Duration(milliseconds: 850),
            child: Text(
              'Connect your watch or health app. Your recent workouts turn into '
              'XP, a starting level and a class that fits how you train.',
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      bottom: Entrance(
        delay: const Duration(milliseconds: 1000),
        child: OnboardingButton(label: 'GET STARTED', onPressed: ctrl.next),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String icon;
  final String title;
  final String date;
  final String xp;
  final bool hot;
  final GlobalKey chipKey;
  final ValueNotifier<int> pulse;
  final int index;

  const _WorkoutCard({
    required this.icon,
    required this.title,
    required this.date,
    required this.xp,
    required this.hot,
    required this.chipKey,
    required this.pulse,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hot
              ? AppColors.purple.withValues(alpha: .55)
              : AppColors.surfaceElevated,
        ),
        boxShadow: hot
            ? [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: .2),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          AppIconImage(icon, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(date,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: pulse,
            builder: (_, active, child) => AnimatedScale(
              scale: active == index ? 1.25 : 1,
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutBack,
              child: child,
            ),
            child: Container(
              key: chipKey,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(9),
                border:
                    Border.all(color: AppColors.orange.withValues(alpha: .3)),
              ),
              child: Text(xp,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.orange)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gentle idle bob so the stack feels alive.
class _Bob extends StatefulWidget {
  final Widget child;
  final double phase;
  const _Bob({required this.child, required this.phase});

  @override
  State<_Bob> createState() => _BobState();
}

class _BobState extends State<_Bob> with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 5));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (onboardingMotion(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(
            0, -3 * math.sin(_c.value * 2 * math.pi + widget.phase)),
        child: child,
      ),
      child: widget.child,
    );
  }
}
