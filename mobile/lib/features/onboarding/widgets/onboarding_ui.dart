import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/class_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/models/character_class.dart';

/// Stat colours used by the class cards (`class_selection_screen`).
const kStatColors = {
  'STR': AppColors.red,
  'END': AppColors.blue,
  'AGI': Color(0xFF38D9C8),
  'FLX': AppColors.purple,
  'STA': AppColors.orange,
};

bool onboardingMotion(BuildContext context) =>
    AppMotion.allowsDecorativeMotion(context);

// ── Scaffold ─────────────────────────────────────────────────────────────────

/// Setup-screen shell: background glow, "STEP x OF 5" + progress dots,
/// optional back button, body, and a CTA area pinned to the bottom.
class OnboardingScaffold extends StatelessWidget {
  final int? step; // 0-based dot index; null hides the step row
  final VoidCallback? onBack;
  final Color glow;
  final Widget body;
  final Widget? bottom;
  final EdgeInsets padding;

  const OnboardingScaffold({
    super.key,
    this.step,
    this.onBack,
    this.glow = AppColors.purple,
    required this.body,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
  });

  static const totalSteps = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.85),
                  radius: 1.15,
                  colors: [glow.withValues(alpha: .14), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (step != null) ...[
                    Row(
                      children: [
                        if (onBack != null) ...[
                          OnboardingBackButton(onTap: onBack!),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          'STEP ${step! + 1} OF $totalSteps',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OnboardingDots(current: step!),
                    ),
                  ],
                  Expanded(child: body),
                  if (bottom != null) ...[
                    const SizedBox(height: 12),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const OnboardingBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Same dots as `setupProgressDots`: done = green, current = blue pill.
class OnboardingDots extends StatelessWidget {
  final int current;
  const OnboardingDots({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(OnboardingScaffold.totalSteps, (i) {
        final done = i < current;
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: done
                ? AppColors.green
                : active
                    ? AppColors.blue
                    : AppColors.surfaceElevated,
            border: done || active ? null : Border.all(color: AppColors.border),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: AppColors.blue.withValues(alpha: .6),
                        blurRadius: 6)
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class OnboardingTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign align;
  const OnboardingTitle(this.title,
      {super.key, this.subtitle, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    final cross = align == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Text(
          title,
          textAlign: align,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: align,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Primary button ───────────────────────────────────────────────────────────

/// The setup flow's purple CTA with an optional light sweep.
class OnboardingButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool shine;
  final Color color;

  const OnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.shine = true,
    this.color = AppColors.purple,
  });

  @override
  State<OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<OnboardingButton>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (onboardingMotion(context) && widget.shine) {
      if (!_sweep.isAnimating) _sweep.repeat();
    } else {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AppPressable(
        onTap: enabled ? widget.onPressed : null,
        haptic: AppHaptic.light,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: enabled || widget.busy ? widget.color : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: .3),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (enabled && widget.shine)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _sweep,
                    builder: (_, __) {
                      final t = (_sweep.value / .35).clamp(0.0, 1.0);
                      if (t <= 0 || t >= 1) return const SizedBox.shrink();
                      return FractionalTranslation(
                        translation: Offset(-1.1 + 2.2 * t, 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: .32),
                              Colors.white.withValues(alpha: 0),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (widget.busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                )
              else
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: enabled ? Colors.white : AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingTextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const OnboardingTextLink(this.text, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Entrances ────────────────────────────────────────────────────────────────

/// Fades + slides [child] in after [delay]. With reduced motion it simply
/// appears. [play] = false keeps it hidden until flipped to true.
class Entrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset from; // logical px
  final double fromScale;
  final Curve curve;
  final bool play;

  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.from = const Offset(0, 16),
    this.fromScale = 1,
    this.curve = Curves.easeOutCubic,
    this.play = true,
  });

  const Entrance.pop({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.play = true,
  })  : from = Offset.zero,
        fromScale = .5,
        curve = Curves.easeOutBack;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(covariant Entrance old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _maybeStart();
  }

  void _maybeStart() {
    if (!widget.play || _c.value > 0 || _timer != null) return;
    if (!onboardingMotion(context)) {
      _c.value = 1;
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final e = widget.curve.transform(_c.value);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.from * (1 - e),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * e,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ── Numbers ──────────────────────────────────────────────────────────────────

String fmtInt(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Rolls a number from its previous value to [value] with ease-out.
class CountUp extends StatefulWidget {
  final num value;
  final Duration duration;
  final TextStyle style;
  final String Function(double v) format;
  final num from;

  CountUp({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
    String Function(double v)? format,
    this.from = 0,
  }) : format = format ?? ((v) => fmtInt(v));

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  late double _from = widget.from.toDouble();
  late double _to = widget.value.toDouble();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!onboardingMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(covariant CountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _current;
      _to = widget.value.toDouble();
      if (onboardingMotion(context)) {
        _c
          ..duration = widget.duration
          ..forward(from: 0);
      } else {
        _c.value = 1;
      }
    }
  }

  double get _current =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_c.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Text(widget.format(_current), style: widget.style),
    );
  }
}

// ── Shake ────────────────────────────────────────────────────────────────────

/// Call `key.currentState?.shake()` for a short camera-shake on impacts.
class Shaker extends StatefulWidget {
  final Widget child;
  const Shaker({super.key, required this.child});

  @override
  State<Shaker> createState() => ShakerState();
}

class ShakerState extends State<Shaker> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  double _amp = 4;

  void shake({double amplitude = 4, int ms = 380}) {
    if (!onboardingMotion(context)) return;
    _amp = amplitude;
    _c.duration = Duration(milliseconds: ms);
    _c.forward(from: 0);
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
      builder: (_, child) {
        final t = _c.value;
        final decay = 1 - t;
        final dx = math.sin(t * math.pi * 7) * _amp * decay;
        final dy = math.cos(t * math.pi * 5) * _amp * .5 * decay;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );
  }
}

// ── Class visuals ────────────────────────────────────────────────────────────

/// Tinted square with the class icon (or both parents' icons for hybrids).
class ClassBadge extends StatelessWidget {
  final String className;
  final double size;
  final double radius;
  final bool glow;

  const ClassBadge({
    super.key,
    required this.className,
    this.size = 60,
    this.radius = 14,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = classColorForName(className);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: .5)),
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 30)]
            : null,
      ),
      alignment: Alignment.center,
      child: ClassIcon(className: className, size: size * .72),
    );
  }
}

/// A class icon; hybrids overlap their two parents' icons.
class ClassIcon extends StatelessWidget {
  final String className;
  final double size;
  const ClassIcon({super.key, required this.className, required this.size});

  @override
  Widget build(BuildContext context) {
    final pair = classIconPairForName(className);
    if (pair != null) {
      final s = size * .68;
      return SizedBox(
        width: size,
        height: size * .9,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, child: AppIconImage(pair.$1, size: s)),
            Positioned(
                right: 0, bottom: 0, child: AppIconImage(pair.$2, size: s)),
          ],
        ),
      );
    }
    final asset = classIconAssetForName(className);
    if (asset == null) {
      return Text('✨', style: TextStyle(fontSize: size * .7));
    }
    return AppIconImage(asset, size: size);
  }
}

List<(String, double)> classBonuses(CharacterClass c) => [
      if (c.strMultiplier > 1) ('STR', c.strMultiplier),
      if (c.endMultiplier > 1) ('END', c.endMultiplier),
      if (c.agiMultiplier > 1) ('AGI', c.agiMultiplier),
      if (c.flxMultiplier > 1) ('FLX', c.flxMultiplier),
      if (c.staMultiplier > 1) ('STA', c.staMultiplier),
    ];

/// "+END x1.3" chips like the class selection cards.
class ClassBonusChips extends StatelessWidget {
  final CharacterClass cls;
  final WrapAlignment alignment;
  const ClassBonusChips(
      {super.key, required this.cls, this.alignment = WrapAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: 5,
      runSpacing: 4,
      children: [
        for (final (stat, m) in classBonuses(cls))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: kStatColors[stat]!.withValues(alpha: .12),
              border: Border.all(color: kStatColors[stat]!.withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+$stat x${m.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: kStatColors[stat],
              ),
            ),
          ),
      ],
    );
  }
}

/// Five stat bars using the class card's fill rule, animated on first build.
class ClassStatBars extends StatelessWidget {
  final CharacterClass cls;
  final Duration delay;
  const ClassStatBars({super.key, required this.cls, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('STR', cls.strMultiplier),
      ('END', cls.endMultiplier),
      ('AGI', cls.agiMultiplier),
      ('FLX', cls.flxMultiplier),
      ('STA', cls.staMultiplier),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 5),
            _StatBar(
              label: rows[i].$1,
              multiplier: rows[i].$2,
              delay: delay + Duration(milliseconds: 60 * i),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final double multiplier;
  final Duration delay;
  const _StatBar(
      {required this.label, required this.multiplier, required this.delay});

  @override
  Widget build(BuildContext context) {
    final color = kStatColors[label]!;
    final boosted = multiplier > 1.0;
    final fill =
        boosted ? (0.3 + (multiplier - 1.0) * 1.5).clamp(0.0, 1.0) : 0.3;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4,
                  color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(height: 4, color: AppColors.surfaceElevated),
                _GrowBar(
                  fill: fill.toDouble(),
                  color: boosted ? color : color.withValues(alpha: .55),
                  glow: boosted,
                  delay: delay,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 20,
          child: Text(
            '${(fill * 100).round()}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: boosted ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _GrowBar extends StatefulWidget {
  final double fill;
  final Color color;
  final bool glow;
  final Duration delay;
  const _GrowBar(
      {required this.fill,
      required this.color,
      required this.glow,
      required this.delay});

  @override
  State<_GrowBar> createState() => _GrowBarState();
}

class _GrowBarState extends State<_GrowBar>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  Timer? _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!onboardingMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && _t == null) {
      _t = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => FractionallySizedBox(
        widthFactor: widget.fill * Curves.easeOutCubic.transform(_c.value),
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            color: widget.color,
            boxShadow: widget.glow
                ? [
                    BoxShadow(
                        color: widget.color.withValues(alpha: .5),
                        blurRadius: 4)
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

// ── Ambient embers ───────────────────────────────────────────────────────────

/// Slow glowing motes drifting up the screen in a class colour.
class Embers extends StatefulWidget {
  final Color color;
  final int count;
  const Embers({super.key, required this.color, this.count = 28});

  @override
  State<Embers> createState() => _EmbersState();
}

class _EmbersState extends State<Embers> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 12));
  final _rng = math.Random(7);
  late final List<(double, double, double, double)> _motes = List.generate(
    widget.count,
    (_) => (
      _rng.nextDouble(), // x
      _rng.nextDouble(), // phase
      .6 + _rng.nextDouble() * 1.4, // radius
      .5 + _rng.nextDouble() * .8, // speed
    ),
  );

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
    if (!onboardingMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _EmberPainter(_motes, _c.value, widget.color),
        ),
      ),
    );
  }
}

class _EmberPainter extends CustomPainter {
  final List<(double, double, double, double)> motes;
  final double t;
  final Color color;
  _EmberPainter(this.motes, this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..blendMode = BlendMode.plus;
    for (final (x, phase, r, speed) in motes) {
      final k = (phase + t * speed) % 1.0;
      final y = size.height * (1 - k);
      final a = math.sin(k * math.pi) * .35;
      final cx = x * size.width + math.sin((k + phase) * 6) * 10;
      p.color = color.withValues(alpha: a);
      canvas.drawCircle(Offset(cx, y), r, p);
      p.color = color.withValues(alpha: a * .22);
      canvas.drawCircle(Offset(cx, y), r * 3.2, p);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.t != t || old.color != color;
}
