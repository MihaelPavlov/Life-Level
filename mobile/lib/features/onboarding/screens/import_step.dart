import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/onboarding_models.dart';
import '../onboarding_controller.dart';
import '../services/onboarding_service.dart';
import '../widgets/activity_visuals.dart';
import '../widgets/onboarding_ui.dart';

/// Step 3 — the import itself. Each recovered workout slides into the feed
/// and its XP flies into the crystal ring, so the wait becomes the reward.
class ImportStep extends StatefulWidget {
  const ImportStep({super.key});

  @override
  State<ImportStep> createState() => _ImportStepState();
}

class _ImportStepState extends State<ImportStep> {
  static const _maxRows = 8;

  final _ringKey = GlobalKey();
  final _listKey = GlobalKey<AnimatedListState>();
  final _rows = <ImportedWorkout>[];
  final _rowXpKeys = <ImportedWorkout, GlobalKey>{};

  OnboardingImportResult? _result;
  String? _error;
  int _xpShown = 0;
  double _ringFill = 0;
  bool _done = false;
  int _pulse = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final ctrl = OnboardingScope.read(context);
    setState(() => _error = null);
    try {
      final result = ctrl.importResult ?? await ctrl.runImport();
      if (!mounted) return;
      setState(() => _result = result);
      await _play(result);
    } on OnboardingSyncException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'We couldn\'t import your history. Check your connection and try again.');
      }
    }
  }

  Future<void> _play(OnboardingImportResult r) async {
    final motion = onboardingMotion(context);
    final shown = r.workouts.take(_maxRows).toList().reversed.toList();
    final shownXp = shown.fold<int>(0, (a, w) => a + w.xp);
    // Rows carry their own XP; spread the rest (older workouts) across them.
    final scale = shownXp > 0 ? r.totalXp / shownXp : 0.0;

    for (final w in shown) {
      if (!mounted) return;
      _rowXpKeys[w] = GlobalKey();
      _rows.insert(0, w);
      _listKey.currentState
          ?.insertItem(0, duration: Duration(milliseconds: motion ? 300 : 0));
      setState(() {});
      if (motion) await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;

      final from = RewardFx.centerOf(_rowXpKeys[w]!);
      final to = RewardFx.centerOf(_ringKey);
      if (motion && from != null && to != null) {
        await RewardFx.fly(
          context,
          child: const _XpOrb(),
          from: from,
          to: to,
          lift: -70,
          sideways: (math.Random().nextDouble() - .5) * 120,
          endScale: .5,
          duration: const Duration(milliseconds: 520),
        );
        if (!mounted) return;
        RewardFx.burst(context, to, AppColors.orange, count: 6, distance: 22);
      }
      setState(() {
        _xpShown = math.min(r.totalXp, _xpShown + (w.xp * scale).round());
        _ringFill = r.totalXp == 0 ? 1 : _xpShown / r.totalXp;
        _pulse++;
      });
      AppMotion.haptic(AppHaptic.selection);
    }

    if (!mounted) return;
    setState(() {
      _xpShown = r.totalXp;
      _ringFill = 1;
      _done = true;
    });
    final c = RewardFx.centerOf(_ringKey);
    if (c != null) {
      RewardFx.ring(context, c, AppColors.orange, maxRadius: 130, stroke: 3);
      RewardFx.burst(context, c, AppColors.orange, count: 22, distance: 110);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final r = _result;
    final fmt = DateFormat('MMM d');
    final sourceName =
        ctrl.source == OnboardingSource.strava ? 'Strava' : 'Health Connect';

    return OnboardingScaffold(
      glow: AppColors.orange,
      body: Column(
        children: [
          const SizedBox(height: 4),
          Entrance.pop(
            child: SizedBox(
              key: _ringKey,
              width: 224,
              height: 224,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: _ringFill),
                    duration: const Duration(milliseconds: 350),
                    builder: (_, v, __) => CustomPaint(
                      size: const Size.square(224),
                      painter: _RingPainter(v),
                    ),
                  ),
                  if (r == null && _error == null)
                    const SizedBox(
                      width: 224,
                      height: 224,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: AppColors.orange),
                    ),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(_pulse),
                    tween: Tween(begin: 1.08, end: 1),
                    duration: const Duration(milliseconds: 220),
                    builder: (_, s, child) =>
                        Transform.scale(scale: s, child: child),
                    child: const AppIconImage(
                      AppIcons.rewardXpCrystals,
                      size: 176,
                      visualScale: 2.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CountUp(
            value: _xpShown,
            duration: const Duration(milliseconds: 260),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
              letterSpacing: -1,
            ),
          ),
          const Text('XP RECOVERED',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _error ??
                  (r == null
                      ? 'Importing your history…'
                      : _done
                          ? r.imported == 0
                              ? 'No workouts in the last 30 days'
                              : 'History imported'
                          : 'Recovering your workouts…'),
              key: ValueKey('${_error != null}$_done${r == null}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _error != null ? 13 : 20,
                fontWeight: FontWeight.w800,
                color: _error != null ? AppColors.red : AppColors.textPrimary,
              ),
            ),
          ),
          if (r?.windowStart != null) ...[
            const SizedBox(height: 4),
            Text(
              '${fmt.format(r!.windowStart!)} → ${fmt.format(r.windowEnd!)} · $sourceName',
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _Stat(
                  label: 'WORKOUTS',
                  value: r?.imported ?? 0,
                  format: (v) => fmtInt(v)),
              const SizedBox(width: 8),
              _Stat(
                  label: 'DISTANCE',
                  value: r?.totalKm ?? 0,
                  format: (v) =>
                      '${v < 10 ? v.toStringAsFixed(1) : v.round()} km'),
              const SizedBox(width: 8),
              _Stat(
                  label: 'ACTIVE',
                  value: (r?.totalMinutes ?? 0) / 60,
                  format: (v) => '${v.toStringAsFixed(v < 10 ? 1 : 0)} h'),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0, .65, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: AnimatedList(
                key: _listKey,
                physics: const NeverScrollableScrollPhysics(),
                initialItemCount: _rows.length,
                itemBuilder: (_, i, anim) => SizeTransition(
                  sizeFactor:
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  child: FadeTransition(
                    opacity: anim,
                    child: _FeedRow(
                      workout: _rows[i],
                      date: fmt.format(_rows[i].performedAt),
                      xpKey: _rowXpKeys[_rows[i]],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottom: _error != null
          ? OnboardingButton(label: 'TRY AGAIN', onPressed: _start)
          : AnimatedOpacity(
              opacity: _done ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: !_done,
                child: OnboardingButton(
                  label: 'SEE MY LEVEL',
                  shine: false,
                  onPressed: ctrl.next,
                ),
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final num value;
  final String Function(double) format;
  const _Stat({required this.label, required this.value, required this.format});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Column(
          children: [
            CountUp(
              value: value,
              duration: const Duration(milliseconds: 2600),
              format: format,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  final ImportedWorkout workout;
  final String date;
  final GlobalKey? xpKey;
  const _FeedRow({required this.workout, required this.date, this.xpKey});

  @override
  Widget build(BuildContext context) {
    final w = workout;
    final detail = w.distanceKm > 0
        ? '${w.distanceKm.toStringAsFixed(1)} km'
        : '${w.durationMinutes} min';
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Row(
          children: [
            AppIconImage(activityIcon(w.type), size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${activityLabel(w.type)} · $detail',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ),
            Text(date,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            SizedBox(
              width: 52,
              child: Text(
                '+${w.xp}',
                key: xpKey,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpOrb extends StatelessWidget {
  const _XpOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orange,
        boxShadow: [
          BoxShadow(
              color: AppColors.orange.withValues(alpha: .8), blurRadius: 12)
        ],
      ),
    );
  }
}

/// Gold progress ring around the XP crystals.
class _RingPainter extends CustomPainter {
  final double fill;
  _RingPainter(this.fill);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
        r,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = AppColors.surfaceElevated);
    if (fill <= 0) return;
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * fill.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [Color(0xFFFFD27A), AppColors.orange, Color(0xFFFFD27A)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fill != fill;
}
