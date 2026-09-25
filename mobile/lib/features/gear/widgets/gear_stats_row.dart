import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../character/models/character_profile.dart';

/// Combat readout for the Gear page: Power alongside Attack / HP / Defense.
/// (Coins stays as its own pill at the top of the page.) All four values are
/// computed server-side (`CombatStatsCalculator`, from core stats + equipped
/// gear + talents) and returned on `CharacterProfile` — this widget is pure
/// display, no client-side formula.
///
/// When the values change (equip / unequip) each changed stat plays an
/// "odometer roll": every digit rolls to its new value like a mechanical
/// counter, the number flashes green or red, and a small ▲/▼ pops in beside
/// it and fades.
class GearStatsRow extends StatefulWidget {
  final CharacterProfile profile;
  const GearStatsRow({super.key, required this.profile});

  @override
  State<GearStatsRow> createState() => _GearStatsRowState();
}

enum _Stat { power, attack, health, defense }

int _valueOf(CharacterProfile p, _Stat s) => switch (s) {
      _Stat.power => p.power,
      _Stat.attack => p.attack,
      _Stat.health => p.health,
      _Stat.defense => p.defense,
    };

// ── Timeline (ms) ────────────────────────────────────────────────────────────
const _kStatStaggerMs = 90.0; // between changed stats, left to right
const _kDigitStaggerMs = 45.0; // per digit, rightmost first
const _kRollMs = 850.0;
const _kFlashMs = 1300.0;
const _kArrowMs = 1700.0;
const _kRollCurve = Cubic(0.2, 0.8, 0.2, 1);

/// Schedule for one stat's roll.
class _Roll {
  final int from;
  final int to;
  final double startMs;
  const _Roll(this.from, this.to, this.startMs);

  bool get up => to > from;
  int get digits => math.max('$from'.length, '$to'.length);
  double get endMs =>
      startMs + math.max(_kArrowMs, (digits - 1) * _kDigitStaggerMs + _kRollMs);

  /// Roll progress of digit [i] (0 = leftmost).
  double digitT(double ms, int i) {
    final delay = (digits - 1 - i) * _kDigitStaggerMs;
    final t = ((ms - startMs - delay) / _kRollMs).clamp(0.0, 1.0);
    return _kRollCurve.transform(t);
  }

  /// 1 while the new value is being revealed, easing back to 0 after 55%.
  double flash(double ms) {
    final q = (ms - startMs) / _kFlashMs;
    if (q < 0 || q >= 1) return 0;
    return q < 0.55 ? 1 : 1 - Curves.easeOut.transform((q - 0.55) / 0.45);
  }

  /// Arrow opacity + vertical offset (slides in from below for ▲, from
  /// above for ▼).
  (double, double) arrow(double ms) {
    final q = (ms - startMs) / _kArrowMs;
    if (q < 0 || q >= 1) return (0, 0);
    if (q < 0.15) {
      final e = Curves.easeOut.transform(q / 0.15);
      return (e, (1 - e) * (up ? 6 : -6));
    }
    if (q < 0.75) return (1, 0);
    return (1 - (q - 0.75) / 0.25, 0);
  }
}

class _GearStatsRowState extends State<GearStatsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this)
    ..addListener(() => setState(() {}))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _rolls = {};
    });

  Map<_Stat, _Roll> _rolls = {};
  double _totalMs = 1;

  double get _ms => _ctrl.value * _totalMs;

  @override
  void didUpdateWidget(GearStatsRow old) {
    super.didUpdateWidget(old);
    final changed = _Stat.values
        .where((s) => _valueOf(old.profile, s) != _valueOf(widget.profile, s))
        .toList();
    if (changed.isEmpty) return;

    _ctrl.stop();
    if (!AppMotion.isFull(context)) {
      _rolls = {};
      return;
    }
    _rolls = {
      for (final (i, s) in changed.indexed)
        s: _Roll(_valueOf(old.profile, s), _valueOf(widget.profile, s),
            i * _kStatStaggerMs),
    };
    _totalMs = _rolls.values.map((r) => r.endMs).fold(1.0, math.max);
    _ctrl.duration = Duration(milliseconds: _totalMs.round());
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(
            _Stat.power,
            Image.asset(
              AppIcons.homePowerIcon,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded,
                  size: 18, color: AppColors.orange),
            ),
            AppColors.orange,
          ),
          _divider(),
          _stat(
            _Stat.attack,
            Image.asset(AppIcons.homeSwordIcon,
                width: 18, height: 18, fit: BoxFit.contain),
            AppColors.textPrimary,
          ),
          _divider(),
          _stat(
            _Stat.health,
            const Icon(Icons.favorite_rounded, size: 18, color: AppColors.red),
            AppColors.textPrimary,
          ),
          _divider(),
          _stat(
            _Stat.defense,
            const Icon(Icons.shield_rounded, size: 18, color: AppColors.blue),
            AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _stat(_Stat s, Widget icon, Color baseColor) {
    final roll = _ctrl.isAnimating ? _rolls[s] : null;
    final ms = _ms;

    Widget number;
    Widget? arrow;

    if (roll == null) {
      number =
          Text('${_valueOf(widget.profile, s)}', style: _valueStyle(baseColor));
    } else {
      final tint = roll.up ? AppColors.green : AppColors.red;
      final k = roll.flash(ms);
      number = _Odometer(
        roll: roll,
        ms: ms,
        style: _valueStyle(
          Color.lerp(baseColor, tint, k)!,
          k > 0
              ? [Shadow(color: tint.withValues(alpha: k), blurRadius: 14)]
              : null,
        ),
      );

      final (opacity, dy) = roll.arrow(ms);
      if (opacity > 0) {
        arrow = Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(
            opacity: opacity,
            child: Text(
              roll.up ? '▲' : '▼',
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w800, color: tint),
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        // The arrow floats just right of the number without taking layout
        // space, so the row doesn't shift while it's visible.
        Stack(
          clipBehavior: Clip.none,
          children: [
            number,
            if (arrow != null) Positioned(right: -12, top: 2, child: arrow),
          ],
        ),
      ],
    );
  }

  static TextStyle _valueStyle(Color color, [List<Shadow>? shadows]) =>
      TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: color,
        shadows: shadows,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  Widget _divider() => Container(
      width: 1, height: 26, color: Colors.white.withValues(alpha: 0.12));
}

/// Renders [roll] at time [ms]: one clipped 0–9 strip per digit, each
/// scrolled from its old digit to its new one. A digit that exists in only
/// one of the two numbers (e.g. 998 → 1004) fades and collapses in or out.
class _Odometer extends StatelessWidget {
  final _Roll roll;
  final double ms;
  final TextStyle style;

  const _Odometer({required this.roll, required this.ms, required this.style});

  @override
  Widget build(BuildContext context) {
    final n = roll.digits;
    final from = '${roll.from}'.padLeft(n);
    final to = '${roll.to}'.padLeft(n);

    final probe = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final w = probe.width, h = probe.height;
    probe.dispose();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++)
          _digit(from[i], to[i], roll.digitT(ms, i), w, h),
      ],
    );
  }

  Widget _digit(String a, String b, double t, double w, double h) {
    final da = a == ' ' ? 0 : int.parse(a);
    final db = b == ' ' ? 0 : int.parse(b);
    final pa = a == ' ' ? 0.0 : 1.0, pb = b == ' ' ? 0.0 : 1.0;
    final presence = pa + (pb - pa) * t;
    if (presence <= 0) return const SizedBox.shrink();

    return Opacity(
      opacity: presence,
      child: SizedBox(
        width: w * presence,
        height: h,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: h * 10,
            maxHeight: h * 10,
            minWidth: w,
            maxWidth: w,
            child: Transform.translate(
              offset: Offset(0, -(da + (db - da) * t) * h),
              child: Column(
                children: [
                  for (var d = 0; d < 10; d++)
                    SizedBox(
                      height: h,
                      child: Center(child: Text('$d', style: style)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
