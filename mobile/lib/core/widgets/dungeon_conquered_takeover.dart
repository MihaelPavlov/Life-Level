import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../motion/app_motion.dart';
import '../motion/reward_fx.dart';
import 'reward_moment/reward_moment.dart';

/// Last floor of a dungeon cleared (design: Rewards canvas, "S1 · Just the
/// ring"). The portal ring draws in one segment per floor, a gold line
/// sweeps around and closes it, the dungeon art turns into a checkmark,
/// then the text, bonus XP and Claim rise in. No rays, sparks or shake.
Future<void> showDungeonConqueredTakeover(
  BuildContext context, {
  required String dungeonName,
  required int totalFloors,
  required int bonusXp,
}) {
  return RewardMoment.showCustomTakeover(
    context,
    barrierLabel: 'Dungeon conquered',
    builder: (_) => _DungeonConqueredView(
      dungeonName: dungeonName,
      totalFloors: math.max(1, totalFloors),
      bonusXp: bonusXp,
    ),
  );
}

// Reveal timeline (ms). Floors share [_floorsStart, _floorsEnd]: each one
// draws over 1.4 steps and the next starts one step later, so they overlap.
const _ringInMs = 300.0;
const _floorsStart = 200.0;
const _floorsEnd = 1400.0;
const _sweepStart = 1500.0;
const _sweepMs = 800.0;
const _closeAt = _sweepStart + _sweepMs; // ring complete
const _checkStart = _closeAt - 100;
const _textStart = 2550.0;
const _textStep = 150.0;
const _riseMs = 500.0;
const _xpAt = _textStart + 3 * _textStep + 50;
const _buttonAt = _xpAt + 200;
const _countMs = 700.0;
const _totalMs = _buttonAt + _riseMs;

const _kGapPx = 16.5; // between floor segments, measured on the ring
const _kRingSize = 200.0;
const _kStroke = 8.0;

/// cubic-bezier(.22, 1, .36, 1): fast start, long soft landing.
const _rise = Cubic(.22, 1, .36, 1);

/// cubic-bezier(.65, 0, .35, 1): draws and sweeps.
const _draw = Cubic(.65, 0, .35, 1);

class _DungeonConqueredView extends StatefulWidget {
  final String dungeonName;
  final int totalFloors;
  final int bonusXp;

  const _DungeonConqueredView({
    required this.dungeonName,
    required this.totalFloors,
    required this.bonusXp,
  });

  @override
  State<_DungeonConqueredView> createState() => _DungeonConqueredViewState();
}

class _DungeonConqueredViewState extends State<_DungeonConqueredView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs.round()),
  )..addListener(_onTick);
  final _xpKey = GlobalKey();
  bool _started = false;
  bool _claimed = false;
  int _floorsBuzzed = 0;
  bool _closeBuzzed = false;

  int get _floors => widget.totalFloors;
  double get _floorStep => (_floorsEnd - _floorsStart) / (_floors + .4);

  double get _ms => _intro.value * _totalMs;

  double _p(double start, double len, [Curve curve = _rise]) =>
      curve.transform(((_ms - start) / len).clamp(0.0, 1.0));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.isFull(context)) {
      _intro.forward();
    } else {
      _floorsBuzzed = _floors;
      _closeBuzzed = true;
      _intro.value = 1;
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  // A light tap as each floor finishes drawing, a firmer one as the ring
  // closes in gold.
  void _onTick() {
    setState(() {});
    while (_floorsBuzzed < _floors &&
        _ms >= _floorsStart + _floorsBuzzed * _floorStep + 1.4 * _floorStep) {
      _floorsBuzzed++;
      AppMotion.haptic(AppHaptic.light);
    }
    if (!_closeBuzzed && _ms >= _closeAt) {
      _closeBuzzed = true;
      AppMotion.haptic(AppHaptic.medium);
    }
  }

  /// First tap during the reveal skips to the end; the next one claims.
  void _onTap() {
    if (_intro.isAnimating) {
      _floorsBuzzed = _floors;
      _closeBuzzed = true;
      _intro.value = 1;
      return;
    }
    _claim();
  }

  Future<void> _claim() async {
    if (_claimed) return;
    setState(() => _claimed = true);
    _intro.value = 1;
    final nav = Navigator.of(context, rootNavigator: true);
    final rewards = [
      if (widget.bonusXp > 0) RewardLine.xp(widget.bonusXp, label: 'Bonus XP'),
    ];
    final flying = RewardMoment.flyToHud(
      nav.context,
      rewards,
      [for (final _ in rewards) RewardFx.centerOf(_xpKey)],
      AppColors.orange,
    );
    // Close as the XP takes off so the avatar ring it lands in is visible.
    if (rewards.isNotEmpty && RewardFx.enabled(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (mounted) nav.pop();
    await flying;
  }

  // ── pieces ────────────────────────────────────────────────────────────────

  Widget _riseIn(double start, Widget child) {
    final p = _p(start, _riseMs);
    if (p >= 1) return child;
    return Opacity(
      opacity: p,
      child: Transform.translate(offset: Offset(0, 12 * (1 - p)), child: child),
    );
  }

  Widget _ring() {
    final ringIn = _p(0, _ringInMs);
    // Swell slightly as the ring closes, then settle.
    final breathe = math.sin(math.pi * _p(_closeAt - 50, 500, Curves.linear));
    final art = _p(_closeAt - 100, 500, _draw);
    return Opacity(
      opacity: ringIn,
      child: Transform.scale(
        scale: (.92 + .08 * ringIn) * (1 + .035 * breathe),
        child: SizedBox(
          width: _kRingSize,
          height: _kRingSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Soft gold glow once the ring is complete.
              Positioned(
                left: -40,
                top: -40,
                right: -40,
                bottom: -40,
                child: Opacity(
                  opacity: _p(_closeAt - 100, 700),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x38F5A623),
                          Color(0x14F5A623),
                          Color(0x00F5A623),
                        ],
                        stops: [0, .45, .7],
                      ),
                    ),
                  ),
                ),
              ),
              CustomPaint(
                size: const Size.square(_kRingSize),
                painter: _PortalRingPainter(
                  floors: _floors,
                  floorProgress: [
                    for (var i = 0; i < _floors; i++)
                      _p(_floorsStart + i * _floorStep, 1.4 * _floorStep,
                          _draw),
                  ],
                  sweep: _p(_sweepStart, _sweepMs, _draw),
                ),
              ),
              if (art < 1)
                Opacity(
                  opacity: 1 - art,
                  child: Transform.scale(
                    scale: 1 - .18 * art,
                    child: Image.asset(
                      AppIcons.zoneTheConvergence,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              CustomPaint(
                size: const Size.square(76),
                painter:
                    _CheckPainter(progress: _p(_checkStart, 500, _draw)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _xpPill() {
    final count = _p(_xpAt, _countMs, Curves.easeOutCubic);
    return Container(
      key: _xpKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(AppIcons.rewardXpCrystals,
              width: 28, height: 28, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Text(
            '+${_fmt((widget.bonusXp * count).round())}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.orange,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'bonus',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floors = _floors;
    return Material(
      color: AppColors.backgroundAlt,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _claimed ? null : _onTap,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Center(child: _ring()),
                const SizedBox(height: 50),
                _riseIn(
                  _textStart,
                  const Text(
                    'DUNGEON CONQUERED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: AppColors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _riseIn(
                  _textStart + _textStep,
                  Text(
                    widget.dungeonName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _riseIn(
                  _textStart + 2 * _textStep,
                  Text(
                    '$floors of $floors ${floors == 1 ? 'trial' : 'trials'} cleared',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
                if (widget.bonusXp > 0) ...[
                  const SizedBox(height: 40),
                  _riseIn(_xpAt, Center(child: _xpPill())),
                ],
                const Spacer(flex: 3),
                _riseIn(
                  _buttonAt,
                  FilledButton(
                    onPressed: _claimed ? null : _claim,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: const Color(0xFF1A0F00),
                      disabledBackgroundColor:
                          AppColors.orange.withValues(alpha: .5),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    child: Text(widget.bonusXp > 0 ? 'Claim' : 'Continue'),
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

/// Empty track, one purple segment per floor drawn in by its progress, and
/// a gold line that sweeps once around from the top.
class _PortalRingPainter extends CustomPainter {
  final int floors;
  final List<double> floorProgress;
  final double sweep;

  _PortalRingPainter({
    required this.floors,
    required this.floorProgress,
    required this.sweep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - _kStroke) / 2 - 2;
    final rect =
        Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
    const full = 2 * math.pi;
    final gap = floors > 1 ? _kGapPx / radius : 0.0;
    final segment = full / floors - gap;
    Paint stroke(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kStroke
      ..strokeCap = StrokeCap.round
      ..color = c;

    final track = stroke(AppColors.surfaceElevated);
    final purple = stroke(AppColors.purple);
    for (var i = 0; i < floors; i++) {
      final start = -math.pi / 2 + gap / 2 + i * (segment + gap);
      canvas.drawArc(rect, start, segment, false, track);
      final p = floorProgress[i];
      if (p > 0) canvas.drawArc(rect, start, segment * p, false, purple);
    }
    if (sweep > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, full * sweep, false, stroke(AppColors.orange));
    }
  }

  @override
  bool shouldRepaint(_PortalRingPainter old) =>
      old.sweep != sweep || !_listEquals(old.floorProgress, floorProgress);

  static bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A checkmark that draws itself along its path.
class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final s = size.width / 24;
    final path = Path()
      ..moveTo(5 * s, 12.5 * s)
      ..lineTo(10 * s, 17.5 * s)
      ..lineTo(19 * s, 7.5 * s);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.orange,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

String _fmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}
