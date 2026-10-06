import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../onboarding/widgets/activity_visuals.dart';
import '../models/pending_models.dart';

/// What the player chose in the review sheet.
class ImportReviewChoice {
  final List<String> ids;

  /// Global centre of the Import button, where the celebration starts.
  final Offset? from;
  const ImportReviewChoice(this.ids, this.from);
}

/// Shows the workouts waiting in the queue. Returns the ids to import, or
/// null when the player closes it or taps Later (they stay queued).
Future<ImportReviewChoice?> showImportReviewSheet(
  BuildContext context,
  PendingWorkoutList list,
) {
  return showAppBottomSheet<ImportReviewChoice>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => ImportReviewSheet(list: list),
  );
}

class ImportReviewSheet extends StatefulWidget {
  final PendingWorkoutList list;
  const ImportReviewSheet({super.key, required this.list});

  @override
  State<ImportReviewSheet> createState() => _ImportReviewSheetState();
}

class _ImportReviewSheetState extends State<ImportReviewSheet> {
  late final Set<String> _selected =
      widget.list.pending.map((w) => w.id).toSet();
  final _buttonKey = GlobalKey();

  List<PendingWorkout> get _chosen =>
      widget.list.pending.where((w) => _selected.contains(w.id)).toList();

  @override
  Widget build(BuildContext context) {
    final pending = widget.list.pending;
    final dups = widget.list.items.where((w) => w.isDuplicate).toList();
    final rejected = widget.list.rejected;
    final chosen = _chosen;
    final xp = chosen.fold<int>(0, (a, w) => a + w.previewXp);
    final km = chosen.fold<double>(0, (a, w) => a + (w.distanceKm ?? 0));
    final sources = {
      for (final w in pending.isNotEmpty ? pending : widget.list.items)
        providerLabel(w.provider),
    }.join(' and ');
    final maxH = MediaQuery.of(context).size.height * .82;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3A4A5A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            pending.isNotEmpty
                ? '${pending.length} new workout${pending.length == 1 ? '' : 's'}'
                : '${widget.list.items.length} workout${widget.list.items.length == 1 ? '' : 's'} found',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            sources.isEmpty ? 'Waiting to be imported' : 'From $sources',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final w in pending)
                    _WorkoutRow(
                      workout: w,
                      selected: _selected.contains(w.id),
                      onTap: () => setState(() {
                        if (!_selected.remove(w.id)) _selected.add(w.id);
                      }),
                    ),
                  for (final w in dups)
                    _WorkoutRow(workout: w, selected: false),
                  for (final w in rejected)
                    _WorkoutRow(workout: w, selected: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (pending.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Gain(AppIcons.rewardXpCrystals, '+$xp XP'),
                for (final g in _statTotals(chosen))
                  _Gain(g.$1, '${g.$2} +${g.$3}'),
                if (km > 0)
                  _Gain(
                      AppIcons.mapDestination, '+${km.toStringAsFixed(1)} km'),
              ],
            ),
          const SizedBox(height: 14),
          if (pending.isNotEmpty)
            _ImportButton(
              key: _buttonKey,
              label: chosen.isEmpty
                  ? 'Select a workout'
                  : 'Import ${chosen.length} · +$xp XP',
              enabled: chosen.isNotEmpty,
              onTap: () {
                final box =
                    _buttonKey.currentContext?.findRenderObject() as RenderBox?;
                final from = box?.localToGlobal(box.size.center(Offset.zero));
                Navigator.of(context).pop(
                    ImportReviewChoice(chosen.map((w) => w.id).toList(), from));
              },
            )
          else
            _ImportButton(
              key: _buttonKey,
              label: 'Done',
              enabled: true,
              onTap: () =>
                  Navigator.of(context).pop(const ImportReviewChoice([], null)),
            ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Later',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const Text(
            'Workouts count on the day you did them, not the day you import.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  List<(String, String, int)> _statTotals(List<PendingWorkout> ws) {
    final rows = <(String, String, int)>[
      (
        AppIcons.statStrength,
        'STR',
        ws.fold(0, (a, w) => a + w.previewStrength)
      ),
      (
        AppIcons.statEndurance,
        'END',
        ws.fold(0, (a, w) => a + w.previewEndurance)
      ),
      (AppIcons.statAgility, 'AGI', ws.fold(0, (a, w) => a + w.previewAgility)),
      (
        AppIcons.statFlexibility,
        'FLX',
        ws.fold(0, (a, w) => a + w.previewFlexibility)
      ),
      (AppIcons.statStamina, 'STA', ws.fold(0, (a, w) => a + w.previewStamina)),
    ];
    return rows.where((r) => r.$3 > 0).toList();
  }
}

String providerLabel(String provider) => switch (provider.toLowerCase()) {
      'strava' => 'Strava',
      'garmin' => 'Garmin',
      'healthconnect' => 'Health Connect',
      'healthkit' => 'Apple Health',
      _ => provider,
    };

Color providerColor(String provider) => switch (provider.toLowerCase()) {
      'strava' => const Color(0xFFFF8A4C),
      'garmin' => AppColors.blue,
      'healthconnect' => AppColors.green,
      'healthkit' => const Color(0xFFFF6B81),
      _ => AppColors.textSecondary,
    };

String _whenLabel(DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final hh = at.hour.toString().padLeft(2, '0');
  final mm = at.minute.toString().padLeft(2, '0');
  final diff = today.difference(day).inDays;
  final dayLabel = diff == 0
      ? 'today'
      : diff == 1
          ? 'yesterday'
          : '${at.day}/${at.month}';
  return '$dayLabel $hh:$mm';
}

class _WorkoutRow extends StatelessWidget {
  final PendingWorkout workout;
  final bool selected;
  final VoidCallback? onTap;
  const _WorkoutRow(
      {required this.workout, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = workout;
    final dup = w.isDuplicate;
    final rejected = w.isRejected;
    final meta = [
      if (w.distanceKm != null && w.distanceKm! > 0)
        '${w.distanceKm!.toStringAsFixed(1)} km',
      '${w.durationMinutes} min',
      _whenLabel(w.performedAt),
    ].join(' · ');
    final pColor = providerColor(w.provider);

    final row = AnimatedContainer(
      duration: AppMotion.duration(context, AppMotionTokens.micro),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.blue.withValues(alpha: .07)
            : const Color(0xFF0F141B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1.5,
          color: selected
              ? AppColors.blue.withValues(alpha: .6)
              : const Color(0xFF262E39),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: AppIconImage(activityIcon(w.activityType), size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityLabel(w.activityType),
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: pColor.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        providerLabel(w.provider),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: pColor),
                      ),
                    ),
                    Text(
                      rejected
                          ? 'Manual entry · rejected'
                          : dup
                              ? 'Same workout as ${providerLabel(w.duplicateOfProvider ?? 'another app')}'
                              : meta,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (dup || rejected)
            Text(
              rejected ? 'No rewards' : 'Duplicate · skipped',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: rejected ? AppColors.red : AppColors.textSecondary),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotionTokens.micro),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        width: 2,
                        color: selected ? AppColors.blue : AppColors.border),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 15, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  '+${w.previewXp} XP',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.orange),
                ),
              ],
            ),
        ],
      ),
    );

    if (dup || rejected) return Opacity(opacity: .55, child: row);
    return Semantics(
      button: true,
      toggled: selected,
      label: '${activityLabel(w.activityType)}, ${providerLabel(w.provider)}, '
          '$meta, plus ${w.previewXp} XP',
      child: AppPressable(
        haptic: AppHaptic.selection,
        onTap: onTap,
        child: row,
      ),
    );
  }
}

class _Gain extends StatelessWidget {
  final String icon;
  final String text;
  const _Gain(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141B),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF262E39)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconImage(icon, size: 15),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ImportButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : .5,
      duration: AppMotion.duration(context, AppMotionTokens.micro),
      child: AppPressable(
        haptic: AppHaptic.light,
        onTap: enabled ? onTap : null,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blue, AppColors.purple],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: .3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
