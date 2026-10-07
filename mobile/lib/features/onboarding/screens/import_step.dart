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

/// Step 3 — the import itself. Each recovered workout slides into the card
/// and its XP flies into the crystal ring, so the wait becomes the reward.
///
/// Layout (design: "History Import Redesign", option C): ring + XP on top,
/// one stats strip, then a fixed workout card — every workout when there are
/// up to 4, otherwise the 3 newest plus a "+N more workouts" row that opens
/// the full list in a sheet. Nothing on the page scrolls.
class ImportStep extends StatefulWidget {
  const ImportStep({super.key});

  @override
  State<ImportStep> createState() => _ImportStepState();
}

class _ImportStepState extends State<ImportStep> {
  /// Up to this many workouts all fit in the card…
  static const _allFit = 4;

  /// …otherwise this many show, followed by the "+N more" row.
  static const _shownWithMore = 3;

  static const _maxRing = 208.0;

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

  List<ImportedWorkout> _visible(OnboardingImportResult r) =>
      r.workouts.length <= _allFit
          ? r.workouts
          : r.workouts.take(_shownWithMore).toList();

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
    // Oldest of the shown rows lands first, so the newest ends on top.
    final shown = _visible(r).reversed.toList();
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

  void _showAll(OnboardingImportResult r) {
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: const Color(0xB802050A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _AllWorkoutsSheet(result: r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final r = _result;
    final fmt = DateFormat('MMM d');
    final sourceName =
        ctrl.source == OnboardingSource.strava ? 'Strava' : 'Health Connect';

    final total = r?.workouts.length ?? _allFit;
    final hidden = r == null ? 0 : total - _visible(r).length;
    final hiddenXp = r == null
        ? 0
        : r.workouts.skip(_visible(r).length).fold<int>(0, (a, w) => a + w.xp);
    // Show the "+XP" on the more row only when rows add up to the total
    // (the history XP is capped, so capped imports would not add up).
    final rowsAddUp =
        r != null && r.workouts.fold<int>(0, (a, w) => a + w.xp) == r.totalXp;
    final hasManual = (r?.rejectedManualCount ?? 0) > 0;

    return OnboardingScaffold(
      glow: AppColors.orange,
      body: Column(
        children: [
          // The ring takes the height the rest leaves (up to 208), so short
          // phones still fit without scrolling and tall ones keep it full size.
          Flexible(
            child: LayoutBuilder(builder: (context, box) {
              final ring = math.max(0.0, math.min(box.maxHeight - 4, _maxRing));
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Entrance.pop(
                  child: SizedBox(
                    key: _ringKey,
                    width: ring,
                    height: ring,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: _ringFill),
                          duration: const Duration(milliseconds: 350),
                          builder: (_, v, __) => CustomPaint(
                            size: Size.square(ring),
                            painter: _RingPainter(v),
                          ),
                        ),
                        if (r == null && _error == null)
                          SizedBox(
                            width: ring,
                            height: ring,
                            child: const CircularProgressIndicator(
                                strokeWidth: 3, color: AppColors.orange),
                          ),
                        TweenAnimationBuilder<double>(
                          key: ValueKey(_pulse),
                          tween: Tween(begin: 1.08, end: 1),
                          duration: const Duration(milliseconds: 220),
                          builder: (_, s, child) =>
                              Transform.scale(scale: s, child: child),
                          // The crystals fill most of the ring.
                          child: AppIconImage(
                            AppIcons.rewardXpCrystals,
                            size: ring * .8,
                            visualScale: 2.75,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          CountUp(
            value: _xpShown,
            duration: const Duration(milliseconds: 260),
            style: const TextStyle(
              fontSize: 36,
              height: 1.1,
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
          if (hasManual) ...[
            const SizedBox(height: 6),
            Text(
              '${r!.rejectedManualCount} manual ${r.rejectedManualCount == 1 ? 'entry' : 'entries'} skipped — only tracked workouts earn XP',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          _StatsStrip(result: r),
          const SizedBox(height: 12),
          _WorkoutCard(
            listKey: _listKey,
            rows: _rows,
            xpKeys: _rowXpKeys,
            fmt: fmt,
            more: _done && hidden > 0
                ? _MoreRow(
                    count: hidden,
                    xp: rowsAddUp ? hiddenXp : null,
                    onTap: () => _showAll(r!),
                  )
                : null,
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

/// Workouts · Active · Distance · Adventure in one strip.
class _StatsStrip extends StatelessWidget {
  final OnboardingImportResult? result;
  const _StatsStrip({required this.result});

  static String _km(double v) =>
      '${v < 10 ? v.toStringAsFixed(1) : v.round()} km';

  @override
  Widget build(BuildContext context) {
    final r = result;
    Widget cell(String label, num value, String Function(double) format,
            {bool first = false, Color color = AppColors.textPrimary}) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: first
                ? null
                : const BoxDecoration(
                    border: Border(
                        left: BorderSide(color: AppColors.surfaceElevated))),
            child: Column(
              children: [
                CountUp(
                  value: value,
                  duration: const Duration(milliseconds: 2600),
                  format: format,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(height: 3),
                Text(label,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .9,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: Row(
        children: [
          cell('WORKOUTS', r?.imported ?? 0, (v) => fmtInt(v), first: true),
          cell('ACTIVE', (r?.totalMinutes ?? 0) / 60,
              (v) => '${v.toStringAsFixed(v < 10 ? 1 : 0)} h'),
          cell('DISTANCE', r?.totalKm ?? 0, _km),
          cell('ADVENTURE', r?.totalAdventureDistanceKm ?? 0, _km,
              color: AppColors.blue),
        ],
      ),
    );
  }
}

/// One card holding the shown workouts (they land one by one) and, once the
/// import finishes, the "+N more" row.
class _WorkoutCard extends StatelessWidget {
  final GlobalKey<AnimatedListState> listKey;
  final List<ImportedWorkout> rows;
  final Map<ImportedWorkout, GlobalKey> xpKeys;
  final DateFormat fmt;
  final Widget? more;
  const _WorkoutCard({
    required this.listKey,
    required this.rows,
    required this.xpKeys,
    required this.fmt,
    required this.more,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            AnimatedList(
              key: listKey,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: rows.length,
              itemBuilder: (_, i, anim) => SizeTransition(
                sizeFactor:
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                child: FadeTransition(
                  opacity: anim,
                  child: _FeedRow(
                    workout: rows[i],
                    date: fmt.format(rows[i].performedAt),
                    xpKey: xpKeys[rows[i]],
                    divider: i > 0,
                  ),
                ),
              ),
            ),
            if (more != null) more!,
          ],
        ),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final int count;
  final int? xp;
  final VoidCallback onTap;
  const _MoreRow({required this.count, required this.xp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.surfaceElevated)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 40,
                child: Icon(Icons.format_list_bulleted_rounded,
                    size: 18, color: AppColors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '+$count more workout${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue),
                ),
              ),
              if (xp != null)
                Text('+$xp',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  final ImportedWorkout workout;
  final String date;
  final GlobalKey? xpKey;
  final bool divider;
  const _FeedRow(
      {required this.workout,
      required this.date,
      this.xpKey,
      this.divider = false});

  @override
  Widget build(BuildContext context) {
    final w = workout;
    final detail = w.distanceKm > 0
        ? '${w.distanceKm.toStringAsFixed(1)} km'
        : '${w.durationMinutes} min';
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 8, right: 14),
      decoration: divider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceElevated)))
          : null,
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
          Text(date,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary)),
          SizedBox(
            width: 52,
            child: Text(
              '+${w.xp}',
              key: xpKey,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every imported workout, grouped by week (Monday start), newest first.
class _AllWorkoutsSheet extends StatelessWidget {
  final OnboardingImportResult result;
  const _AllWorkoutsSheet({required this.result});

  static DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String _weekLabel(DateTime start, DateTime thisWeek) {
    if (start == thisWeek) return 'THIS WEEK';
    if (start == thisWeek.subtract(const Duration(days: 7))) {
      return 'LAST WEEK';
    }
    final end = start.add(const Duration(days: 6));
    final from = DateFormat('MMM d').format(start);
    final to = end.month == start.month
        ? DateFormat('d').format(end)
        : DateFormat('MMM d').format(end);
    return '$from – $to'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    final fmt = DateFormat('MMM d');
    final thisWeek = _weekStart(r.windowEnd ?? DateTime.now());
    final weeks = <DateTime, List<ImportedWorkout>>{};
    for (final w in r.workouts) {
      weeks.putIfAbsent(_weekStart(w.performedAt), () => []).add(w);
    }
    final total = r.workouts.fold<int>(0, (a, w) => a + w.xp);

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .86),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A4552),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('All imported workouts',
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            children: [
                              TextSpan(
                                  text:
                                      '${r.workouts.length} workout${r.workouts.length == 1 ? '' : 's'}'),
                              if (r.windowStart != null)
                                TextSpan(
                                    text:
                                        ' · ${fmt.format(r.windowStart!)} → ${fmt.format(r.windowEnd!)}'),
                              const TextSpan(text: ' · '),
                              TextSpan(
                                  text: '+$total XP',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.orange)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final MapEntry(key: start, value: list)
                      in weeks.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(_weekLabel(start, thisWeek),
                                style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.3,
                                    color: AppColors.textSecondary)),
                          ),
                          Text('+${list.fold<int>(0, (a, w) => a + w.xp)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceElevated),
                      ),
                      child: Column(
                        children: [
                          for (final (i, w) in list.indexed)
                            _FeedRow(
                              workout: w,
                              date: fmt.format(w.performedAt),
                              divider: i > 0,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
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
