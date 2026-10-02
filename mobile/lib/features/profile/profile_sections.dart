import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/motion/reward_fx.dart';
import '../../core/widgets/app_icon_image.dart';
import '../activity/models/activity_models.dart';
import '../activity/providers/activity_provider.dart';
import '../character/models/character_profile.dart';
import '../character/providers/character_provider.dart';
import '../home/providers/world_progress_provider.dart';
import '../streak/providers/streak_provider.dart';
import '../talents/models/talent_models.dart';
import '../talents/providers/talents_provider.dart';
import '../talents/widgets/talent_theme.dart';
import '../titles/providers/titles_provider.dart';
import 'profile_stat_metadata.dart';
import 'stat_detail_sheet.dart';

// ── shared bits ──────────────────────────────────────────────────────────────

/// Section label ("STATS", "PERSONAL RECORDS"…).
class ProfileSectionLabel extends StatelessWidget {
  final String text;
  const ProfileSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.2,
          color: kPTextSec,
        ),
      );
}

/// Rises and fades in after [delay]; instant when motion is off.
class ProfileRise extends StatefulWidget {
  final Duration delay;
  final Widget child;
  const ProfileRise({super.key, required this.delay, required this.child});

  @override
  State<ProfileRise> createState() => _ProfileRiseState();
}

class _ProfileRiseState extends State<ProfileRise>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!AppMotion.isFull(context)) {
        _c.value = 1;
        return;
      }
      await Future<void>.delayed(widget.delay);
      if (mounted) _c.forward();
    });
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
        final t = const Cubic(.22, 1, .36, 1).transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
              offset: Offset(0, 26 * (1 - t)), child: child),
        );
      },
      child: widget.child,
    );
  }
}

BoxDecoration _card({Color? border}) => BoxDecoration(
      color: kPSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border ?? kPBorder2),
    );

/// Grabber + title row + close button used by the profile's sheets.
class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? icon;
  const _SheetHeader({required this.title, required this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF3A4A5A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Row(
            children: [
              if (icon != null) ...[
                AppIconImage(icon!, size: 30),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: kPTextPri)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: kPTextSec)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  backgroundColor: kPSurface2,
                  minimumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon:
                    const Icon(Icons.close_rounded, size: 20, color: kPTextPri),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _showProfileSheet(BuildContext context, Widget child) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kPSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => child,
  );
}

// ── stats ────────────────────────────────────────────────────────────────────

/// The five core stats as one row of tiles. "+" shows only while there are
/// points to spend; tapping a tile opens its detail sheet.
class ProfileStatsSection extends StatelessWidget {
  final CharacterProfile profile;
  const ProfileStatsSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final points = profile.availableStatPoints;
    final stats = buildProfileStats(profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: ProfileSectionLabel('STATS')),
            if (points > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.green.withValues(alpha: .45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlipSwap(
                      value: points,
                      child: Text('+$points',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.green)),
                    ),
                    Text(' ${points == 1 ? 'point' : 'points'} to spend',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _StatTile(stat: stats[i], availablePoints: points),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const Text('Tap a stat to see what raises it.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _StatTile extends ConsumerStatefulWidget {
  final StatData stat;
  final int availablePoints;
  const _StatTile({required this.stat, required this.availablePoints});

  @override
  ConsumerState<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends ConsumerState<_StatTile>
    with SingleTickerProviderStateMixin {
  bool _spending = false;
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  final _valueKey = GlobalKey();

  @override
  void didUpdateWidget(_StatTile old) {
    super.didUpdateWidget(old);
    final gained = widget.stat.value - old.stat.value;
    if (old.stat.key != widget.stat.key || gained <= 0) return;
    if (!RewardFx.enabled(context)) return;
    _glow.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = RewardFx.centerOf(_valueKey);
      if (p != null) {
        RewardFx.floatText(
            context, p + const Offset(0, -16), '+$gained', AppColors.green,
            rise: 24, duration: const Duration(milliseconds: 900));
      }
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _spend() async {
    setState(() => _spending = true);
    AppMotion.haptic(AppHaptic.light);
    try {
      await ref
          .read(characterProfileProvider.notifier)
          .spendStatPoint(widget.stat.key);
    } catch (_) {
      // The profile refresh stays the source of truth.
    } finally {
      if (mounted) setState(() => _spending = false);
    }
  }

  void _showDetail() {
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatDetailSheet(
        stat: widget.stat,
        availablePoints: widget.availablePoints,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stat;
    final canAdd = widget.availablePoints > 0;
    final pct = (s.value / 100.0).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) {
        final g = _glow.isAnimating ? math.sin(_glow.value * math.pi) : 0.0;
        return Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
          decoration: BoxDecoration(
            color: kPSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Color.lerp(kPBorder2, s.color, g) ?? kPBorder2),
            boxShadow: g > 0
                ? [
                    BoxShadow(
                        color: s.color.withValues(alpha: .35 * g),
                        blurRadius: 14)
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          Semantics(
            button: true,
            label: '${s.label} ${s.value}. Tap for details',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showDetail,
              child: Column(
                children: [
                  AppIconImage(s.iconAsset, size: 24),
                  const SizedBox(height: 3),
                  KeyedSubtree(
                    key: _valueKey,
                    child: SlotNumber(
                      '${s.value}',
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: kPTextPri,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(s.key,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: kPTextSec)),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(height: 4, color: kPSurface2),
                        TweenAnimationBuilder<double>(
                          tween: Tween(end: pct),
                          duration: AppMotion.duration(
                              context, const Duration(milliseconds: 500)),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => FractionallySizedBox(
                            widthFactor: v,
                            child: Container(height: 4, color: s.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (canAdd) ...[
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: 'Add a point to ${s.label}',
              child: GestureDetector(
                onTap: _spending ? null : _spend,
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.green.withValues(alpha: .5)),
                  ),
                  child: _spending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.green),
                        )
                      : const Icon(Icons.add_rounded,
                          size: 20, color: AppColors.green),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── personal records ─────────────────────────────────────────────────────────

class ProfileRecordsSection extends ConsumerWidget {
  const ProfileRecordsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(activityCalendarProvider).valueOrNull;
    final streak = ref.watch(streakProvider).valueOrNull;
    final titles = ref.watch(titlesProvider).valueOrNull;
    final world = ref.watch(worldProgressProvider).valueOrNull;

    String km(double v) =>
        v <= 0 ? '—' : '${v.toStringAsFixed(v >= 100 ? 0 : 1)} km';

    final records = [
      (
        AppIcons.activityRunning,
        calendar == null ? '…' : km(calendar.longestRunKm),
        'Longest run'
      ),
      (
        AppIcons.rewardStreakFire,
        streak == null
            ? '…'
            : '${streak.longest} ${streak.longest == 1 ? 'day' : 'days'}',
        'Best streak'
      ),
      (
        AppIcons.ringBoss,
        titles == null ? '…' : '${titles.rankProgression.bossesDefeated}',
        'Bosses defeated'
      ),
      (
        AppIcons.mapDestination,
        world == null
            ? '…'
            : '${world.userProgress.unlockedZoneIds.length} / ${world.zones.length}',
        'Zones reached'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionLabel('PERSONAL RECORDS'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.55,
          children: [
            for (final (icon, value, label) in records)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: _card(),
                child: Row(
                  children: [
                    AppIconImage(icon, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(value,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: kPTextPri)),
                          ),
                          const SizedBox(height: 2),
                          Text(label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10.5, color: kPTextSec)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── talent bonuses ───────────────────────────────────────────────────────────

class ProfileTalentBonusesSection extends StatelessWidget {
  final TalentSummary talents;
  const ProfileTalentBonusesSection({super.key, required this.talents});

  static const _visible = 4;

  @override
  Widget build(BuildContext context) {
    final lines = talents.effectLines;
    final shown = lines.take(_visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionLabel('TALENT BONUSES'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.purple.withValues(alpha: .12), kPSurface],
              stops: const [0, .6],
            ),
            border: Border.all(color: AppColors.purple.withValues(alpha: .35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final l in shown) _BonusChip(l)],
              ),
              if (lines.length > _visible) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _showProfileSheet(
                        context, _TalentBonusesSheet(talents: talents)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.purple.withValues(alpha: .12),
                      foregroundColor: const Color(0xFFC9A7FF),
                      side: BorderSide(
                          color: AppColors.purple.withValues(alpha: .4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('See all ${lines.length} bonuses',
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BonusChip extends StatelessWidget {
  final String text;
  const _BonusChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 13, color: AppColors.purple),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kPTextPri)),
          ),
        ],
      ),
    );
  }
}

/// Every talent bonus, with the talent (and level) it comes from.
class _TalentBonusesSheet extends ConsumerWidget {
  final TalentSummary talents;
  const _TalentBonusesSheet({required this.talents});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(talentsProvider).valueOrNull;
    final owned = <TalentView>[
      ...?screen?.talents.where((t) => t.owned),
    ]..sort((a, b) => b.level.compareTo(a.level));
    final maxH = MediaQuery.sizeOf(context).height * .8;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              title: 'Talent bonuses',
              subtitle: '${talents.effectLines.length} bonuses from '
                  '${talents.ownedCount} talents',
              icon: AppIcons.talentCrystalIcon,
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  if (screen == null)
                    for (final l in talents.effectLines)
                      _BonusRow(title: l, subtitle: null, icon: null)
                  else
                    for (final t in owned)
                      _BonusRow(
                        title: t.effectText,
                        subtitle: '${t.name} · Lv ${t.level}',
                        icon: talentIconAsset(t.key),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? icon;
  const _BonusRow({required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPBorder2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: icon != null
                ? AppIconImage(icon!, size: 22)
                : const Icon(Icons.auto_awesome,
                    size: 18, color: AppColors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kPTextPri)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 11.5, color: kPTextSec)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── weeks ────────────────────────────────────────────────────────────────────

const _kShades = [
  Color(0xFF1E2632),
  Color(0xFF1B4A2A),
  Color(0xFF2A7A3E),
  Color(0xFF3FB950),
];
const _kMonths = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];
const _kMonthNames = [
  'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', //
  'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
];

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Monday of the week holding [d].
DateTime _weekStart(DateTime d) =>
    _day(d).subtract(Duration(days: d.weekday - 1));

class _Week {
  final DateTime start;
  final List<ActivityCalendarDay?> days; // Mon..Sun
  const _Week(this.start, this.days);

  int get workouts => days.fold(0, (s, d) => s + (d?.workouts ?? 0));
  double get km => days.fold(0.0, (s, d) => s + (d?.distanceKm ?? 0));
  String get label => '${_kMonths[start.month - 1]} ${start.day}';
}

/// The last [count] weeks, oldest first, ending with this week.
List<_Week> _weeks(ActivityCalendar cal, int count, DateTime today) {
  final byDay = {for (final d in cal.days) _day(d.date): d};
  final thisWeek = _weekStart(today);
  return [
    for (var w = count - 1; w >= 0; w--)
      () {
        final start = thisWeek.subtract(Duration(days: 7 * w));
        return _Week(start, [
          for (var i = 0; i < 7; i++) byDay[start.add(Duration(days: i))],
        ]);
      }(),
  ];
}

Color _shade(ActivityCalendarDay? d) =>
    _kShades[math.min(d?.workouts ?? 0, _kShades.length - 1)];

class ProfileWeeksSection extends ConsumerWidget {
  const ProfileWeeksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cal = ref.watch(activityCalendarProvider).valueOrNull ??
        ActivityCalendar.empty;
    final today = DateTime.now().toUtc();
    final weeks = _weeks(cal, 12, today);
    final total = weeks.fold(0, (s, w) => s + w.workouts);
    final todayUtc = _day(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: ProfileSectionLabel('LAST 12 WEEKS')),
            Semantics(
              button: true,
              label: '$total workouts. Open workout history',
              child: GestureDetector(
                onTap: () =>
                    _showProfileSheet(context, const _WorkoutHistorySheet()),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.green.withValues(alpha: .4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total workouts',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.green)),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: AppColors.green),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            color: kPSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kPBorder2),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < weeks.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Semantics(
                        label: 'Week of ${weeks[i].label}, '
                            '${weeks[i].workouts} workouts',
                        child: Column(
                          children: [
                            for (var d = 0; d < 7; d++) ...[
                              if (d > 0) const SizedBox(height: 4),
                              Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: weeks[i]
                                          .start
                                          .add(Duration(days: d))
                                          .isAfter(todayUtc)
                                      ? Colors.transparent
                                      : _shade(weeks[i].days[d]),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < weeks.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        i == weeks.length - 1
                            ? 'Now'
                            : (i == 0 ||
                                    weeks[i].start.month !=
                                        weeks[i - 1].start.month)
                                ? _kMonths[weeks[i].start.month - 1][0] +
                                    _kMonths[weeks[i].start.month - 1]
                                        .substring(1)
                                        .toLowerCase()
                                : '',
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: i == weeks.length - 1
                              ? const Color(0xFF7DB6FF)
                              : const Color(0xFF6E7681),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// All weeks or month by month, back to the first workout (up to a year).
class _WorkoutHistorySheet extends ConsumerStatefulWidget {
  const _WorkoutHistorySheet();

  @override
  ConsumerState<_WorkoutHistorySheet> createState() =>
      _WorkoutHistorySheetState();
}

class _WorkoutHistorySheetState extends ConsumerState<_WorkoutHistorySheet> {
  bool _months = false;

  @override
  Widget build(BuildContext context) {
    final cal = ref.watch(activityCalendarProvider).valueOrNull ??
        ActivityCalendar.empty;
    final today = DateTime.now().toUtc();
    final first = cal.days.isEmpty
        ? _day(today)
        : cal.days
            .map((d) => _day(d.date))
            .reduce((a, b) => a.isBefore(b) ? a : b);
    final weekCount = math.max(
        1, _weekStart(today).difference(_weekStart(first)).inDays ~/ 7 + 1);
    final weeks = _weeks(cal, math.min(weekCount, 53), today).reversed.toList();
    final total = cal.days.fold(0, (s, d) => s + d.workouts);

    // Months from the first workout's month to this one, newest first.
    final months = <(DateTime, int, double, int)>[];
    var m = DateTime.utc(today.year, today.month);
    final firstMonth = DateTime.utc(first.year, first.month);
    while (!m.isBefore(firstMonth) && months.length < 13) {
      final inMonth = cal.days
          .where((d) => d.date.year == m.year && d.date.month == m.month);
      months.add((
        m,
        inMonth.fold(0, (s, d) => s + d.workouts),
        inMonth.fold(0.0, (s, d) => s + d.distanceKm),
        inMonth.fold(0, (s, d) => s + d.xp),
      ));
      m = DateTime.utc(
          m.month == 1 ? m.year - 1 : m.year, m.month == 1 ? 12 : m.month - 1);
    }
    final maxMonth = months.fold(1, (s, x) => math.max(s, x.$2));

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Column(
          children: [
            _SheetHeader(
              title: 'Workout history',
              subtitle: cal.days.isEmpty
                  ? 'No workouts yet'
                  : '$total workouts since '
                      '${_kMonthNames[first.month - 1][0]}'
                      '${_kMonthNames[first.month - 1].substring(1).toLowerCase()}',
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0B111A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPBorder2),
              ),
              child: Row(
                children: [
                  _tab('All weeks', !_months,
                      () => setState(() => _months = false)),
                  const SizedBox(width: 4),
                  _tab('By month', _months,
                      () => setState(() => _months = true)),
                ],
              ),
            ),
            Expanded(
              child: _months
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        for (var i = 0; i < months.length; i++)
                          _MonthRow(
                            name: _kMonthNames[months[i].$1.month - 1],
                            workouts: months[i].$2,
                            km: months[i].$3,
                            xp: months[i].$4,
                            pct: months[i].$2 / maxMonth,
                            current: i == 0,
                          ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        for (var i = 0; i < weeks.length; i++)
                          _WeekRow(
                              week: weeks[i],
                              current: i == 0,
                              today: _day(today)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool on, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        selected: on,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotionTokens.micro),
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: on
                        ? const Color(0xFF04140A)
                        : const Color(0xFFAAB4C0))),
          ),
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final _Week week;
  final bool current;
  final DateTime today;
  const _WeekRow(
      {required this.week, required this.current, required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: current ? AppColors.blue.withValues(alpha: .5) : kPBorder2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(week.label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                    color: kPTextSec)),
          ),
          SizedBox(
            width: 112,
            child: Row(
              children: [
                for (var d = 0; d < 7; d++) ...[
                  if (d > 0) const SizedBox(width: 3),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: week.start.add(Duration(days: d)).isAfter(today)
                            ? Colors.transparent
                            : _shade(week.days[d]),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  '${week.workouts} ${week.workouts == 1 ? 'workout' : 'workouts'}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: kPTextPri)),
              Text('${week.km.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 11, color: kPTextSec)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  final String name;
  final int workouts;
  final double km;
  final int xp;
  final double pct;
  final bool current;

  const _MonthRow({
    required this.name,
    required this.workouts,
    required this.km,
    required this.xp,
    required this.pct,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPBorder2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: kPTextSec)),
              ),
              Text('$workouts ${workouts == 1 ? 'workout' : 'workouts'}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: kPTextPri)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: kPSurface2),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    color: current ? AppColors.green : const Color(0xFF2A7A3E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('${km.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 11.5, color: kPTextSec)),
              ),
              Text('${fmtXp(xp)} XP',
                  style: const TextStyle(fontSize: 11.5, color: kPTextSec)),
            ],
          ),
        ],
      ),
    );
  }
}
