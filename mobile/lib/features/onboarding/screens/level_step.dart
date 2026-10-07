import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_ui.dart';

/// Step 4 — the head start. The bar fills level by level (faster each time),
/// the number drops in, and a HEAD START stamp slams down.
class LevelStep extends StatefulWidget {
  const LevelStep({super.key});

  @override
  State<LevelStep> createState() => _LevelStepState();
}

class _LevelStepState extends State<LevelStep> with TickerProviderStateMixin {
  final _shaker = GlobalKey<ShakerState>();
  final _numberKey = GlobalKey();
  final _stampKey = GlobalKey();
  late final _bar = AnimationController(vsync: this);
  late final _stamp = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));

  int _shownLevel = 1;
  int _dropTick = 0;
  bool _settled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _bar.dispose();
    _stamp.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final ctrl = OnboardingScope.read(context);
    try {
      await ctrl.loadLevel();
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t load your level.');
      return;
    }
    if (!mounted) return;
    final profile = ctrl.profile!;
    final import = ctrl.importResult;
    final target = profile.level;
    final start = import != null && import.leveledUp
        ? import.previousLevel.clamp(1, target)
        : target;
    final motion = onboardingMotion(context);
    setState(() => _shownLevel = start);

    await Future.delayed(Duration(milliseconds: motion ? 700 : 0));
    for (var l = start; l < target; l++) {
      if (!mounted) return;
      final ms = motion ? (520 - (l - start) * 70).clamp(180, 520) : 0;
      _bar.duration = Duration(milliseconds: ms);
      await _bar.forward(from: 0);
      if (!mounted) return;
      setState(() {
        _shownLevel = l + 1;
        _dropTick++;
      });
      AppMotion.haptic(AppHaptic.light);
      final c = RewardFx.centerOf(_numberKey);
      if (c != null) {
        RewardFx.ring(context, c, AppColors.purple, maxRadius: 90);
        RewardFx.burst(context, c, AppColors.purple, count: 14, distance: 70);
      }
      if (l + 1 == target) _shaker.currentState?.shake(amplitude: 3, ms: 260);
      await Future.delayed(Duration(milliseconds: motion ? 90 : 0));
    }
    if (!mounted) return;

    _bar.duration = Duration(milliseconds: motion ? 700 : 0);
    _bar.value = 0;
    await _bar.animateTo(profile.xpProgress.clamp(0.0, 1.0));
    if (!mounted) return;

    if (target > start) {
      await _stamp.forward(from: 0);
      if (!mounted) return;
      _shaker.currentState?.shake();
      AppMotion.haptic(AppHaptic.light);
      final c = RewardFx.centerOf(_stampKey);
      if (c != null) RewardFx.confetti(context, c, count: 60);
    }
    setState(() => _settled = true);
  }

  Future<void> _continue() async {
    final ctrl = OnboardingScope.read(context);
    await ctrl.acknowledgeReceipts();
    ctrl.next();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final profile = ctrl.profile;
    final import = ctrl.importResult;
    final gained = import != null && import.leveledUp
        ? (profile?.level ?? 1) - import.previousLevel
        : 0;
    final statPoints =
        ctrl.receipts.fold<int>(0, (a, r) => a + r.totalStatPoints);
    final items = [for (final r in ctrl.receipts) ...r.grantedItems];

    return Shaker(
      key: _shaker,
      child: OnboardingScaffold(
        glow: AppColors.purple,
        body: Column(
          children: [
            const SizedBox(height: 10),
            const Text('CALCULATING YOUR STARTING LEVEL',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppColors.purple)),
            const SizedBox(height: 28),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Entrance.pop(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 700),
                  child: SizedBox(
                    width: 176,
                    height: 196,
                    child: CustomPaint(
                      painter: const OnboardingHexPainter(),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('LEVEL',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6,
                                    color: AppColors.purple)),
                            TweenAnimationBuilder<double>(
                              key: ValueKey(_dropTick),
                              tween: Tween(begin: _dropTick == 0 ? 1 : 0, end: 1),
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.easeOutBack,
                              builder: (_, t, child) => Opacity(
                                opacity: t.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, -30 * (1 - t)),
                                  child: Transform.scale(
                                      scale: 1.3 - .3 * t, child: child),
                                ),
                              ),
                              child: Text(
                                '$_shownLevel',
                                key: _numberKey,
                                style: const TextStyle(
                                  fontSize: 78,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  letterSpacing: -2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -58,
                  bottom: -6,
                  child: AnimatedBuilder(
                    animation: _stamp,
                    builder: (_, child) {
                      final t = Curves.easeIn.transform(_stamp.value);
                      return Opacity(
                        opacity: _stamp.value == 0 ? 0 : 1,
                        child: Transform.rotate(
                          angle: -.12,
                          child: Transform.scale(
                              scale: 2.2 - 1.2 * t, child: child),
                        ),
                      );
                    },
                    child: Container(
                      key: _stampKey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.orange, width: 2.5),
                      ),
                      child: const Text('HEAD START',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: AppColors.orange)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 260,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Level $_shownLevel',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      if (_settled && profile != null)
                        Text(
                          '${(profile.xpProgress * 100).round()}% to Level ${profile.level + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Container(color: AppColors.surfaceElevated),
                          AnimatedBuilder(
                            animation: _bar,
                            builder: (_, __) => FractionallySizedBox(
                              widthFactor: _bar.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [AppColors.blue, AppColors.purple]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_settled && profile != null)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((import?.totalXp ?? 0) > 0)
                    _Gain(
                        icon: AppIcons.rewardXpCrystals,
                        // The crystal art has more padding; scale it up to
                        // match the Power icon's footprint.
                        iconScale: 2.3,
                        text: '${fmtInt(import!.totalXp)} XP',
                        delay: 0),
                  _Gain(
                      icon: AppIcons.homePowerIcon,
                      iconScale: 1.05,
                      text: '${fmtInt(profile.power)} Power',
                      delay: 110),
                  if (statPoints > 0)
                    _Gain(
                        text: '+$statPoints stat point${statPoints == 1 ? '' : 's'}',
                        delay: 220),
                  for (var i = 0; i < items.length; i++)
                    _Gain(text: items[i].name, delay: 330 + i * 110),
                ],
              ),
            if (_settled) ...[
              const SizedBox(height: 18),
              Entrance(
                delay: const Duration(milliseconds: 250),
                child: OnboardingTitle(
                  gained > 0
                      ? 'You skip ${gained == 1 ? 'the first level' : 'the first $gained levels'}'
                      : _noSkipTitle(profile?.xpProgress ?? 0),
                  align: TextAlign.center,
                  subtitle: (import?.imported ?? 0) > 0
                      ? '${fmtInt(import!.totalXp)} XP from ${import.imported} workouts. '
                          'Past workouts count at half XP. Your streak and quests start today.'
                      : 'Log your first workout and your hero starts climbing.',
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ),
          ],
        ),
        bottom: _error != null
            ? OnboardingButton(
                label: 'TRY AGAIN',
                onPressed: () {
                  setState(() => _error = null);
                  _run();
                })
            : AnimatedOpacity(
                opacity: _settled ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: IgnorePointer(
                  ignoring: !_settled,
                  child: OnboardingButton(
                      label: 'READ MY TRAINING', onPressed: _continue),
                ),
              ),
      ),
    );
  }
}

/// Title when setup didn't skip any levels. It must agree with the
/// "N% to Level 2" line above it, so a brand-new hero at 0% isn't told the
/// level is almost done.
String _noSkipTitle(double xpProgress) {
  final pct = (xpProgress * 100).round();
  if (pct >= 50) return 'Your first level is almost done';
  if (pct > 0) return 'Your first level is underway';
  return 'Your adventure starts at Level 1';
}

class _Gain extends StatelessWidget {
  final String? icon;
  final double iconScale;
  final String text;
  final int delay;
  const _Gain(
      {this.icon,
      this.iconScale = AppIconImage.defaultVisualScale,
      required this.text,
      required this.delay});

  @override
  Widget build(BuildContext context) {
    return Entrance.pop(
      delay: Duration(milliseconds: delay),
      child: Container(
        // Same height for every chip, with or without an icon.
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIconImage(icon!, size: 32, visualScale: iconScale),
              const SizedBox(width: 6),
            ],
            Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
