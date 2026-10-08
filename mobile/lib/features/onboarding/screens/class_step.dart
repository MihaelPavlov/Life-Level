import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/class_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/models/character_class.dart';
import '../models/onboarding_models.dart';
import '../onboarding_controller.dart';
import '../widgets/activity_visuals.dart';
import '../widgets/onboarding_ui.dart';

/// Step 6 — the class reveal. Each detection state gets its own moment:
/// clear/balanced (emblem), devoted (ring + stamp + trait), hybrid/multisport
/// (versus → merge), close (versus → choose), insufficient (picker).
class ClassStep extends StatefulWidget {
  const ClassStep({super.key});

  @override
  State<ClassStep> createState() => _ClassStepState();
}

class _ClassStepState extends State<ClassStep> {
  final _shaker = GlobalKey<ShakerState>();
  ClassRecommendation? _rec;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final ctrl = OnboardingScope.read(context);
    setState(() => _error = null);
    try {
      final rec = await ctrl.loadRecommendation();
      if (mounted) setState(() => _rec = rec);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t load classes. Try again.');
    }
  }

  void _openPicker() async {
    final ctrl = OnboardingScope.read(context);
    final rec = _rec!;
    final picked = await showAppBottomSheet<CharacterClass>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClassPickerSheet(rec: rec, selected: ctrl.chosenClass),
    );
    if (picked != null && mounted) ctrl.chooseClass(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final rec = _rec;
    final chosen = ctrl.chosenClass;
    final color = chosen == null ? AppColors.blue : classColorForName(chosen.name);
    final state = rec?.state;
    final devoted = state == ClassDetectionState.devoted &&
        chosen?.id == rec?.recommendedClassId;

    Widget body;
    if (_error != null) {
      body = Center(
          child: Text(_error!,
              style: const TextStyle(color: AppColors.red, fontSize: 13)));
    } else if (rec == null) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.purple));
    } else {
      body = switch (rec.state) {
        ClassDetectionState.devoted => _DevotedReveal(rec: rec, shaker: _shaker),
        ClassDetectionState.hybrid ||
        ClassDetectionState.multisport ||
        ClassDetectionState.close =>
          _VersusReveal(rec: rec, shaker: _shaker),
        ClassDetectionState.insufficient => _ManualPicker(rec: rec),
        _ => _EmblemReveal(rec: rec, shaker: _shaker),
      };
    }

    final showChange = rec != null &&
        (state == ClassDetectionState.clear ||
            state == ClassDetectionState.balanced ||
            state == ClassDetectionState.devoted);

    return Shaker(
      key: _shaker,
      child: OnboardingScaffold(
        step: 3,
        onBack: ctrl.canLeaveClassStep ? ctrl.back : null,
        glow: color,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        body: Stack(
          children: [
            if (chosen != null && state != ClassDetectionState.insufficient)
              Positioned.fill(child: Embers(color: color)),
            body,
          ],
        ),
        bottom: rec == null
            ? (_error != null
                ? OnboardingButton(label: 'TRY AGAIN', onPressed: _load)
                : null)
            : Entrance(
                delay: const Duration(milliseconds: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OnboardingButton(
                      label: chosen == null
                          ? 'PICK A CLASS'
                          : 'CONTINUE AS ${devoted ? 'DEVOTED ' : ''}${chosen.name.toUpperCase()}',
                      onPressed: chosen == null
                          ? null
                          : () {
                              final c = RewardFx.centerOf(_shaker);
                              if (c != null) {
                                RewardFx.burst(context, c, color, count: 14);
                              }
                              ctrl.next();
                            },
                    ),
                    if (showChange)
                      OnboardingTextLink('Choose a different class',
                          onTap: _openPicker)
                    else
                      const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Shared pieces ────────────────────────────────────────────────────────────

class _Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const _Eyebrow(this.text, this.color);

  @override
  Widget build(BuildContext context) => Center(
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: color)),
      );
}

/// Class name that de-blurs while its letter-spacing tightens.
class _RevealName extends StatelessWidget {
  final String text;
  final Duration delay;
  final double size;
  const _RevealName(this.text,
      {super.key, this.delay = Duration.zero, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final motion = onboardingMotion(context);
    return _Delayed(
      delay: motion ? delay : Duration.zero,
      builder: (visible) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: visible ? 1 : 0),
        duration: Duration(milliseconds: motion ? 760 : 0),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => Opacity(
          opacity: t,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
                sigmaX: 8 * (1 - t), sigmaY: 8 * (1 - t)),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                letterSpacing: 14 * (1 - t) - .3,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Delayed extends StatefulWidget {
  final Duration delay;
  final Widget Function(bool visible) builder;
  const _Delayed({required this.delay, required this.builder});

  @override
  State<_Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<_Delayed> {
  bool _on = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () {
      if (mounted) setState(() => _on = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_on);
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .4)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      );
}

/// Stacked bar of class-group shares with a legend.
class _MixBar extends StatelessWidget {
  final ClassRecommendation rec;
  const _MixBar({required this.rec});

  @override
  Widget build(BuildContext context) {
    final shares = rec.shares.where((s) => s.share > 0).toList();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(
                  milliseconds: onboardingMotion(context) ? 900 : 0),
              curve: Curves.easeOutCubic,
              builder: (_, t, __) => Row(
                children: [
                  for (final s in shares)
                    Expanded(
                      flex: math.max(1, (s.share * 1000 * t).round()),
                      child: Container(
                        margin: const EdgeInsets.only(right: 2),
                        color: classColorForName(s.className),
                      ),
                    ),
                  if (t < 1)
                    Expanded(
                      flex: math.max(1, ((1 - t) * 1000).round()),
                      child: const ColoredBox(color: AppColors.surfaceElevated),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final s in shares)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: classColorForName(s.className),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(classSportLabel(s.className).split(' ').first,
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(width: 4),
                  Text('${(s.share * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ── Clear / balanced: emblem ─────────────────────────────────────────────────

class _EmblemReveal extends StatefulWidget {
  final ClassRecommendation rec;
  final GlobalKey<ShakerState> shaker;
  const _EmblemReveal({required this.rec, required this.shaker});

  @override
  State<_EmblemReveal> createState() => _EmblemRevealState();
}

class _EmblemRevealState extends State<_EmblemReveal> {
  final _badgeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 650), _impact);
  }

  void _impact() {
    if (!mounted) return;
    final cls = OnboardingScope.read(context).chosenClass;
    final c = RewardFx.centerOf(_badgeKey);
    if (c == null || cls == null) return;
    final color = classColorForName(cls.name);
    RewardFx.ring(context, c, color, maxRadius: 120, stroke: 3);
    RewardFx.burst(context, c, color, count: 28, distance: 110);
    RewardFx.rays(context, c, color, radius: 110);
    widget.shaker.currentState?.shake(amplitude: 3, ms: 240);
    AppMotion.haptic(AppHaptic.light);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final rec = widget.rec;
    final cls = ctrl.chosenClass ?? rec.recommended;
    if (cls == null) return const SizedBox();
    final color = classColorForName(cls.name);
    final balanced = rec.state == ClassDetectionState.balanced;
    final detected = cls.id == rec.recommendedClassId;
    final runnerUp = rec.alternatives.where((c) => c.id != cls.id).firstOrNull;
    final topSport = rec.shares.isEmpty
        ? ''
        : classSportLabel(rec.shares.first.className).toLowerCase();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _Eyebrow(
              !detected
                  ? 'YOUR CHOICE'
                  : balanced
                      ? 'YOUR TRAINING IS BALANCED'
                      : 'CLASS DETECTED FROM YOUR DATA',
              color),
          Center(
            child: _Emblem(
              key: ValueKey(cls.id),
              badgeKey: _badgeKey,
              className: cls.name,
            ),
          ),
          _RevealName(cls.name,
              key: ValueKey('n${cls.id}'),
              delay: const Duration(milliseconds: 250)),
          const SizedBox(height: 6),
          Center(
            child: Entrance.pop(
              key: ValueKey('p${cls.id}'),
              delay: const Duration(milliseconds: 400),
              child: _Pill(
                  balanced && detected
                      ? 'ALL-ROUNDER'
                      : '${(rec.shareOf(cls.id) * 100).round()}% MATCH',
                  color),
            ),
          ),
          const SizedBox(height: 8),
          Entrance(
            delay: const Duration(milliseconds: 500),
            child: Text(
              !detected
                  ? cls.description
                  : balanced
                      ? 'No sport passes 40% of your time. Sentinels get stronger from everything you do.'
                      : 'Most of your active time is $topSport, so ${cls.name} fits you best.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          Entrance(
              delay: const Duration(milliseconds: 580),
              child: _MixBar(rec: rec)),
          const SizedBox(height: 10),
          Entrance(
            delay: const Duration(milliseconds: 660),
            child: ClassBonusChips(cls: cls, alignment: WrapAlignment.center),
          ),
          const SizedBox(height: 10),
          Entrance(
            delay: const Duration(milliseconds: 740),
            child: ClassStatBars(
                key: ValueKey('s${cls.id}'),
                cls: cls,
                delay: const Duration(milliseconds: 800)),
          ),
          if (runnerUp != null) ...[
            const SizedBox(height: 10),
            Entrance(
              delay: const Duration(milliseconds: 820),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: Row(
                  children: [
                    ClassIcon(className: runnerUp.name, size: 34),
                    const SizedBox(width: 10),
                    Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'Runner-up: '),
                        TextSpan(
                            text: runnerUp.name,
                            style:
                                const TextStyle(color: AppColors.textPrimary)),
                        TextSpan(
                            text:
                                ' · ${(rec.shareOf(runnerUp.id) * 100).round()}%'),
                      ]),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Badge that spins in inside two rune rings and slow light rays.
class _Emblem extends StatefulWidget {
  final String className;
  final GlobalKey badgeKey;
  const _Emblem({super.key, required this.className, required this.badgeKey});

  static const size = 200.0;

  @override
  State<_Emblem> createState() => _EmblemState();
}

class _EmblemState extends State<_Emblem> with TickerProviderStateMixin {
  late final _spin = AnimationController(
      vsync: this, duration: const Duration(seconds: 18));
  late final _in = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (onboardingMotion(context)) {
      if (!_spin.isAnimating) _spin.repeat();
      if (_in.value == 0) _in.forward();
    } else {
      _in.value = 1;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = classColorForName(widget.className);
    const s = _Emblem.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _in]),
        builder: (_, __) {
          final t = _in.value;
          // Overshoot: 0.2 → 1.12 at 75% → 1.
          final scale = t < .75
              ? .2 + (1.12 - .2) * Curves.easeOut.transform(t / .75)
              : 1.12 - .12 * ((t - .75) / .25);
          final rot = (1 - Curves.easeOutCubic.transform(t)) * -3.5;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: .18 * t,
                child: Transform.rotate(
                  angle: -_spin.value * 2 * math.pi * .6,
                  child: CustomPaint(
                      size: const Size.square(s), painter: _RaysPainter(color)),
                ),
              ),
              Transform.rotate(
                angle: _spin.value * 2 * math.pi,
                child: CustomPaint(
                    size: const Size.square(s * .9),
                    painter: _RunePainter(color.withValues(alpha: .35), dash: true)),
              ),
              CustomPaint(
                  size: const Size.square(s * .74),
                  painter: _RunePainter(color.withValues(alpha: .2))),
              Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: rot,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      key: widget.badgeKey,
                      child: ClassBadge(
                          className: widget.className,
                          size: 128,
                          radius: 32,
                          glow: true),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RunePainter extends CustomPainter {
  final Color color;
  final bool dash;
  _RunePainter(this.color, {this.dash = false});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = dash ? 1.5 : 1
      ..color = color;
    if (!dash) {
      canvas.drawCircle(c, r, p);
      return;
    }
    const n = 48;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a,
          math.pi / n * .9, false, p);
    }
  }

  @override
  bool shouldRepaint(_RunePainter old) => old.color != color;
}

class _RaysPainter extends CustomPainter {
  final Color color;
  _RaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final p = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r));
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * math.cos(a - .07), c.dy + r * math.sin(a - .07))
        ..lineTo(c.dx + r * math.cos(a + .07), c.dy + r * math.sin(a + .07))
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}

// ── Devoted ──────────────────────────────────────────────────────────────────

class _DevotedReveal extends StatefulWidget {
  final ClassRecommendation rec;
  final GlobalKey<ShakerState> shaker;
  const _DevotedReveal({required this.rec, required this.shaker});

  @override
  State<_DevotedReveal> createState() => _DevotedRevealState();
}

class _DevotedRevealState extends State<_DevotedReveal>
    with TickerProviderStateMixin {
  late final _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));
  late final _stamp = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360));
  final _stampKey = GlobalKey();
  final _traitKey = GlobalKey();
  bool _after = false;

  double get _share => widget.rec.activities.isEmpty
      ? 0
      : widget.rec.activities.first.share;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (!onboardingMotion(context)) {
      _ring.value = 1;
      _stamp.value = 1;
      setState(() => _after = true);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _ring.forward();
    if (!mounted) return;
    await _stamp.forward();
    if (!mounted) return;
    widget.shaker.currentState?.shake(amplitude: 5, ms: 420);
    AppMotion.haptic(AppHaptic.light);
    final c = RewardFx.centerOf(_stampKey);
    if (c != null) {
      RewardFx.burst(context, c, AppColors.orange, count: 30, distance: 80);
      RewardFx.confetti(context, c, count: 40);
    }
    setState(() => _after = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final t = RewardFx.centerOf(_traitKey);
    if (t != null) {
      RewardFx.ring(context, t, AppColors.orange, maxRadius: 50);
      RewardFx.burst(context, t, AppColors.orange, count: 14);
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final rec = widget.rec;
    final cls = ctrl.chosenClass ?? rec.recommended!;
    final keepsTrait = cls.id == rec.recommendedClassId;
    final sport = rec.devotedActivityType ?? 'Running';
    final color = classColorForName(cls.name);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const _Eyebrow('ONE SPORT, EVERY DAY', AppColors.orange),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (_, __) => CustomPaint(
                      size: const Size.square(190),
                      painter: _DevotionRing(
                          color,
                          _share *
                              const Cubic(.3, 0, .2, 1).transform(_ring.value)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIconImage(activityIcon(sport), size: 88),
                      AnimatedBuilder(
                        animation: _ring,
                        builder: (_, __) => Text(
                          '${(_share * 100 * const Cubic(.3, 0, .2, 1).transform(_ring.value)).round()}%',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      Text(sport.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  Positioned(
                    right: -22,
                    top: 12,
                    child: AnimatedBuilder(
                      animation: _stamp,
                      builder: (_, child) => Opacity(
                        opacity: _stamp.value == 0 ? 0 : 1,
                        child: Transform.rotate(
                          angle: .14,
                          child: Transform.scale(
                            scale: 2.6 -
                                1.6 * Curves.easeIn.transform(_stamp.value),
                            child: child,
                          ),
                        ),
                      ),
                      child: Container(
                        key: _stampKey,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: .85),
                          borderRadius: BorderRadius.circular(9),
                          border:
                              Border.all(color: AppColors.orange, width: 2.5),
                        ),
                        child: const Text('DEVOTED',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.4,
                                color: AppColors.orange)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_after) ...[
            const SizedBox(height: 6),
            _RevealName(keepsTrait ? 'Devoted ${cls.name}' : cls.name,
                key: ValueKey('dn${cls.id}'), size: 28),
            const SizedBox(height: 4),
            Entrance(
              delay: const Duration(milliseconds: 200),
              child: Text(
                keepsTrait
                    ? '${(_share * 100).round()}% of your time is ${sport.toLowerCase()}. You get the ${cls.name} class and a devotion trait on top.'
                    : 'You chose ${cls.name}. The devotion trait stays with ${rec.recommended?.name ?? 'your detected class'}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            Entrance(
              delay: const Duration(milliseconds: 330),
              from: const Offset(0, 18),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: .5)),
                ),
                child: Row(
                  children: [
                    ClassBadge(className: cls.name, size: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cls.name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary)),
                          Text(cls.tagline,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          ClassBonusChips(cls: cls),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (keepsTrait) ...[
              const SizedBox(height: 12),
              Entrance(
                delay: const Duration(milliseconds: 700),
                duration: const Duration(milliseconds: 560),
                from: const Offset(60, 0),
                fromScale: .9,
                curve: Curves.easeOutBack,
                child: Container(
                  key: _traitKey,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.orange.withValues(alpha: .12),
                      AppColors.surface,
                    ], stops: const [0, .7]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.orange.withValues(alpha: .45)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.orange.withValues(alpha: .4)),
                        ),
                        alignment: Alignment.center,
                        child: const AppIconImage(AppIcons.rewardStreakFire,
                            size: 42),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trait · Devoted ${_runnerWord(sport)}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              '+10% XP on ${sport.toLowerCase()}. Kept while it stays above 75% of your month.',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _runnerWord(String sport) => switch (sport.toLowerCase()) {
        'running' => 'Runner',
        'cycling' => 'Rider',
        'swimming' => 'Swimmer',
        'yoga' => 'Yogi',
        'gym' => 'Lifter',
        'climbing' => 'Climber',
        'hiking' => 'Hiker',
        'walking' => 'Walker',
        _ => 'Athlete',
      };
}

class _DevotionRing extends CustomPainter {
  final Color color;
  final double fill;
  _DevotionRing(this.color, this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final r = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
        r,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = AppColors.surfaceElevated);
    if (fill <= 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * fill, false, p);
  }

  @override
  bool shouldRepaint(_DevotionRing old) => old.fill != fill || old.color != color;
}

// ── Hybrid / multisport / close: versus ──────────────────────────────────────

class _VersusReveal extends StatefulWidget {
  final ClassRecommendation rec;
  final GlobalKey<ShakerState> shaker;
  const _VersusReveal({required this.rec, required this.shaker});

  @override
  State<_VersusReveal> createState() => _VersusRevealState();
}

class _VersusRevealState extends State<_VersusReveal>
    with TickerProviderStateMixin {
  late final _slide = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 560));
  late final _vs = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  late final _merge = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final _hybrid = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  final _vsKey = GlobalKey();
  bool _counted = false;
  bool _showOptions = false;

  bool get _hasHybrid =>
      widget.rec.state == ClassDetectionState.hybrid ||
      widget.rec.state == ClassDetectionState.multisport;

  List<CharacterClass> get _sides {
    final rec = widget.rec;
    if (rec.state == ClassDetectionState.close) {
      return [rec.recommended, ...rec.alternatives]
          .whereType<CharacterClass>()
          .take(2)
          .toList();
    }
    return rec.alternatives.take(2).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final motion = onboardingMotion(context);
    if (!motion) {
      _slide.value = 1;
      _vs.value = 1;
      if (_hasHybrid) {
        _merge.value = 1;
        _hybrid.value = 1;
      }
      setState(() {
        _counted = true;
        _showOptions = true;
      });
      return;
    }
    await _slide.forward();
    if (!mounted) return;
    await _vs.forward();
    if (!mounted) return;
    widget.shaker.currentState?.shake(amplitude: 3, ms: 300);
    AppMotion.haptic(AppHaptic.light);
    var c = RewardFx.centerOf(_vsKey);
    if (c != null) {
      RewardFx.burst(context, c, AppColors.orange, count: 26, distance: 60);
      RewardFx.ring(context, c, AppColors.orange, maxRadius: 60);
    }
    setState(() => _counted = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    if (_hasHybrid) {
      c = RewardFx.centerOf(_vsKey);
      await _merge.forward();
      if (!mounted) return;
      final rec = widget.rec;
      final h = rec.recommended!;
      if (c != null) {
        RewardFx.ring(context, c, Colors.white, maxRadius: 140, stroke: 3);
        RewardFx.ring(context, c, classColorForName(h.name), maxRadius: 100);
        for (final s in _sides) {
          RewardFx.burst(context, c, classColorForName(s.name),
              count: 20, distance: 90);
        }
      }
      widget.shaker.currentState?.shake(amplitude: 4, ms: 360);
      AppMotion.haptic(AppHaptic.light);
      await _hybrid.forward();
      if (!mounted) return;
    }
    setState(() => _showOptions = true);
  }

  @override
  void dispose() {
    _slide.dispose();
    _vs.dispose();
    _merge.dispose();
    _hybrid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final rec = widget.rec;
    final sides = _sides;
    if (sides.length < 2) return _EmblemReveal(rec: rec, shaker: widget.shaker);
    final hybrid = _hasHybrid ? rec.recommended : null;
    final options = [if (hybrid != null) hybrid, ...sides];

    Widget card(CharacterClass cls, int dir) {
      final color = classColorForName(cls.name);
      final pct = (rec.shareOf(cls.id) * 100).round();
      return AnimatedBuilder(
        animation: Listenable.merge([_slide, _merge]),
        builder: (_, child) {
          final s = Curves.easeOutBack.transform(_slide.value);
          final m = Curves.easeIn.transform(_merge.value);
          return Opacity(
            opacity: (_slide.value * (1 - m)).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(dir * (120 * (1 - s)) - dir * 70 * m, 0),
              child: Transform.rotate(
                angle: dir * .14 * (1 - s),
                child: Transform.scale(scale: 1 - .4 * m, child: child),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: .55), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .15), blurRadius: 24)
            ],
          ),
          child: Column(
            children: [
              ClassBadge(className: cls.name, size: 80),
              const SizedBox(height: 6),
              Text(cls.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              CountUp(
                value: _counted ? pct : 0,
                duration: const Duration(milliseconds: 900),
                format: (v) => '${v.round()}%',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: color),
              ),
              Text(classSportLabel(cls.name),
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _Eyebrow(
              rec.state == ClassDetectionState.multisport
                  ? 'SWIM · BIKE · RUN'
                  : 'TOO CLOSE TO CALL',
              AppColors.purple),
          const SizedBox(height: 12),
          SizedBox(
            height: 236,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: card(sides[0], -1)),
                    const SizedBox(width: 12),
                    Expanded(child: card(sides[1], 1)),
                  ],
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([_vs, _merge]),
                  builder: (_, child) {
                    final v = Curves.easeIn.transform(_vs.value);
                    final m = _merge.value;
                    return Opacity(
                      opacity: (_vs.value * (1 - m)).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: -.5 * (1 - v) + m * math.pi,
                        child: Transform.scale(
                            scale: (3 - 2 * v) * (1 - .8 * m), child: child),
                      ),
                    );
                  },
                  child: Container(
                    key: _vsKey,
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1017),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.orange, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.orange.withValues(alpha: .45),
                            blurRadius: 24)
                      ],
                    ),
                    child: const Text('VS',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: AppColors.orange)),
                  ),
                ),
                if (hybrid != null)
                  AnimatedBuilder(
                    animation: _hybrid,
                    builder: (_, child) {
                      final t = _hybrid.value;
                      final scale = t < .7
                          ? .3 + .76 * Curves.easeOut.transform(t / .7)
                          : 1.06 - .06 * ((t - .7) / .3);
                      return Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    // Scales down rather than overflowing with large text.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _HybridCard(cls: hybrid, parents: sides),
                    ),
                  ),
              ],
            ),
          ),
          if (_showOptions) ...[
            const SizedBox(height: 10),
            Entrance(
              child: Text(
                hybrid != null
                    ? 'You split your time almost evenly, so you get a class that combines both. You can still pick one side.'
                    : 'You train both about equally. Pick the path you want to grow.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Entrance(
                  delay: Duration(milliseconds: 120 + i * 90),
                  child: _OptionRow(
                    cls: options[i],
                    recommended: options[i].id == rec.recommendedClassId,
                    selected: ctrl.chosenClass?.id == options[i].id,
                    onTap: () => ctrl.chooseClass(options[i]),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HybridCard extends StatelessWidget {
  final CharacterClass cls;
  final List<CharacterClass> parents;
  const _HybridCard({required this.cls, required this.parents});

  @override
  Widget build(BuildContext context) {
    final color = classColorForName(cls.name);
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .7), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 50)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('HYBRID CLASS FOUND',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: color)),
          const SizedBox(height: 6),
          ClassIcon(className: cls.name, size: 100),
          Text(cls.name,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(parents.map((p) => p.name).join(' + '),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final CharacterClass cls;
  final bool recommended;
  final bool selected;
  final VoidCallback onTap;
  const _OptionRow(
      {required this.cls,
      required this.recommended,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = classColorForName(cls.name);
    return AppPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .06) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: .6)
                : AppColors.surfaceElevated,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClassBadge(className: cls.name, size: 50, radius: 12),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(cls.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('RECOMMENDED',
                              style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                  color: color)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClassBonusChips(cls: cls),
                ],
              ),
            ),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.purple : Colors.transparent,
          border: Border.all(
              color: selected ? AppColors.purple : AppColors.border,
              width: 1.5),
        ),
        child: selected
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      );
}

// ── Insufficient: manual picker ──────────────────────────────────────────────

class _ManualPicker extends StatelessWidget {
  final ClassRecommendation rec;
  const _ManualPicker({required this.rec});

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final classes = rec.pickable;
    final hand = ctrl.source == null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Entrance(
            child: OnboardingTitle(
              'Choose Your Class',
              subtitle:
                  'Your class shapes which stats grow fastest. Hybrid classes unlock from your training later.',
            ),
          ),
          if (!hand) ...[
            const SizedBox(height: 12),
            Entrance(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: .35)),
                ),
                child: Row(
                  children: [
                    _WorkoutsRing(count: rec.workoutCount),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rec.workoutCount == 0
                            ? 'We didn\'t find workouts from the last 30 days. Pick the class that sounds like you.'
                            : 'We found ${rec.workoutCount} workout${rec.workoutCount == 1 ? '' : 's'}, too few to read your style. Pick the class that sounds like you.',
                        style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.45,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
            children: [
              for (var i = 0; i < classes.length; i++)
                Entrance(
                  delay: Duration(milliseconds: 300 + i * 70),
                  fromScale: .94,
                  curve: Curves.easeOutBack,
                  child: _GridClass(
                    cls: classes[i],
                    selected: ctrl.chosenClass?.id == classes[i].id,
                    onTap: () {
                      ctrl.chooseClass(classes[i]);
                      AppMotion.haptic(AppHaptic.selection);
                    },
                  ),
                ),
              Entrance(
                delay: Duration(milliseconds: 300 + classes.length * 70),
                child: const _LockedHybridTile(),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _WorkoutsRing extends StatelessWidget {
  final int count;
  const _WorkoutsRing({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (count / 3).clamp(0.0, 1.0)),
            duration: Duration(milliseconds: onboardingMotion(context) ? 900 : 0),
            builder: (_, v, __) => SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 5,
                color: AppColors.orange,
                backgroundColor: AppColors.surfaceElevated,
              ),
            ),
          ),
          Text('$count/3',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _GridClass extends StatelessWidget {
  final CharacterClass cls;
  final bool selected;
  final VoidCallback onTap;
  const _GridClass(
      {required this.cls, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = classColorForName(cls.name);
    final isNew = const {'tidecaller', 'cragborn', 'wayfarer'}
        .contains(cls.name.toLowerCase());
    return AppPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .06) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: .6) : AppColors.surfaceElevated,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: .15), blurRadius: 16)]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClassBadge(className: cls.name, size: 46, radius: 11),
                const Spacer(),
                Row(
                  children: [
                    Text(cls.name,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    if (isNew) ...[
                      const SizedBox(width: 5),
                      const Text('NEW',
                          style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange)),
                    ],
                  ],
                ),
                Text(
                  classBonuses(cls)
                      .map((b) => '+${b.$1} x${b.$2.toStringAsFixed(1)}')
                      .join(' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
            Positioned(right: 0, top: 0, child: _Radio(selected: selected)),
          ],
        ),
      ),
    );
  }
}

class _LockedHybridTile extends StatelessWidget {
  const _LockedHybridTile();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .55,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
                opacity: .7,
                child: ClassIcon(className: 'Spellblade', size: 46)),
            Spacer(),
            Text('🔒 Hybrids',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text('Unlock when you train two styles',
                style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── "Choose a different class" sheet ─────────────────────────────────────────

class _ClassPickerSheet extends StatefulWidget {
  final ClassRecommendation rec;
  final CharacterClass? selected;
  const _ClassPickerSheet({required this.rec, required this.selected});

  @override
  State<_ClassPickerSheet> createState() => _ClassPickerSheetState();
}

class _ClassPickerSheetState extends State<_ClassPickerSheet> {
  late String? _selectedId = widget.selected?.id;

  @override
  Widget build(BuildContext context) {
    final rec = widget.rec;
    final classes = [...rec.pickable]
      ..sort((a, b) => rec.shareOf(b.id).compareTo(rec.shareOf(a.id)));
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Choose your class',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              const Text('Share of your last 30 days of active time',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < classes.length; i++)
                      Entrance(
                        delay: Duration(milliseconds: 80 + i * 45),
                        from: const Offset(0, 10),
                        child: _PickerRow(
                          cls: classes[i],
                          share: rec.shareOf(classes[i].id),
                          selected: _selectedId == classes[i].id,
                          onTap: () =>
                              setState(() => _selectedId = classes[i].id),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OnboardingButton(
                label: 'CONFIRM',
                shine: false,
                onPressed: _selectedId == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        classes.firstWhere((c) => c.id == _selectedId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final CharacterClass cls;
  final double share;
  final bool selected;
  final VoidCallback onTap;
  const _PickerRow(
      {required this.cls,
      required this.share,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = classColorForName(cls.name);
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: AppPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.purple.withValues(alpha: .08)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.purple : AppColors.border),
          ),
          child: Row(
            children: [
              ClassBadge(className: cls.name, size: 50, radius: 11),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(cls.name,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        const Spacer(),
                        Text('${(share * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Container(color: AppColors.surface),
                            FractionallySizedBox(
                              widthFactor: share.clamp(.02, 1.0),
                              child: Container(color: color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}
