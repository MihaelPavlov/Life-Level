import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/motion/reward_fx.dart';
import '../../core/widgets/app_icon_image.dart';
import '../character/models/character_profile.dart';
import '../character/providers/character_provider.dart';
import '../streak/widgets/streak_detail_sheet.dart';
import 'profile_stat_metadata.dart';
import 'profile_widgets.dart';
import 'stat_detail_sheet.dart';
import 'xp_history_sheet.dart';

class ProfileOverviewTab extends StatelessWidget {
  final CharacterProfile profile;

  const ProfileOverviewTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      children: [
        ProfileXpSection(profile: profile),
        const SizedBox(height: 20),
        ProfileStatsSection(
          stats: buildProfileStats(profile),
          availablePoints: profile.availableStatPoints,
        ),
        if (profile.talents?.hasAny ?? false) ...[
          const SizedBox(height: 20),
          _TalentBonusSection(talents: profile.talents!),
        ],
        const SizedBox(height: 20),
        ProfileActivitySummary(profile: profile),
      ],
    );
  }
}

/// XP card. Gains fill the bar like liquid (the bar swells and a wave rides
/// the leading edge); a level-up fills to the brim, sloshes, flashes
/// LEVEL UP and refills from zero for the new level.
class ProfileXpSection extends StatefulWidget {
  final CharacterProfile profile;

  const ProfileXpSection({super.key, required this.profile});

  @override
  State<ProfileXpSection> createState() => _ProfileXpSectionState();
}

class _ProfileXpSectionState extends State<ProfileXpSection>
    with TickerProviderStateMixin {
  CharacterProfile get profile => widget.profile;

  late final AnimationController _fill = AnimationController(vsync: this)
    ..addListener(() => setState(() {}));
  late final AnimationController _wave = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
  late final AnimationController _slosh = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))
    ..addListener(() => setState(() {}));
  final _levelKey = GlobalKey();
  final _cardKey = GlobalKey();

  // Values shown while an animation runs (null → use the profile).
  double? _pctFrom, _pctTo;
  int? _xpFrom, _xpTo;
  int? _levelShown;
  bool _rushing = false;

  @override
  void didUpdateWidget(ProfileXpSection old) {
    super.didUpdateWidget(old);
    final o = old.profile, n = widget.profile;
    if (n.level == o.level && n.xp <= o.xp) return;
    if (n.level < o.level || !RewardFx.enabled(context)) return;
    if (n.level == o.level) {
      _animate(o.xpProgress, n.xpProgress, o.xp, n.xp,
          const Duration(milliseconds: 1100));
    } else {
      _levelUp(o, n);
    }
  }

  Future<void> _animate(
      double from, double to, int xpFrom, int xpTo, Duration d) async {
    _pctFrom = from;
    _pctTo = to;
    _xpFrom = xpFrom;
    _xpTo = xpTo;
    setState(() => _rushing = true);
    _wave.repeat();
    _fill.duration = d;
    await _fill.forward(from: 0).orCancel.catchError((_) {});
    if (!mounted) return;
    _wave.stop();
    setState(() {
      _rushing = false;
      _pctFrom = _pctTo = null;
      _xpFrom = _xpTo = null;
    });
  }

  Future<void> _levelUp(CharacterProfile o, CharacterProfile n) async {
    _levelShown = o.level;
    await _animate(o.xpProgress, 1, o.xp, o.xpForNextLevel,
        const Duration(milliseconds: 800));
    if (!mounted) return;
    _slosh.forward(from: 0);
    final card = RewardFx.rectOf(_cardKey);
    if (card != null) {
      RewardFx.floatText(context, card.center, 'LEVEL UP', Colors.white,
          fontSize: 26,
          rise: 30,
          popScale: 1.15,
          duration: const Duration(milliseconds: 1400));
    }
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final lv = RewardFx.centerOf(_levelKey);
    if (lv != null) RewardFx.ring(context, lv, kPBlue, maxRadius: 50);
    setState(() => _levelShown = null);
    await _animate(0, n.xpProgress, n.xpForCurrentLevel, n.xp,
        const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _fill.dispose();
    _wave.dispose();
    _slosh.dispose();
    super.dispose();
  }

  static void _showXPHistory(BuildContext context) {
    showAppBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const XpHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animating = _pctTo != null;
    final e = Curves.easeOutCubic.transform(_fill.value);
    final pct =
        animating ? _pctFrom! + (_pctTo! - _pctFrom!) * e : profile.xpProgress;
    final xpShown =
        animating ? (_xpFrom! + (_xpTo! - _xpFrom!) * e).round() : profile.xp;
    final level = _levelShown ?? profile.level;
    final nextAt = _levelShown != null ? _xpTo! : profile.xpForNextLevel;
    final remaining = nextAt - xpShown;
    final sloshK = _slosh.isAnimating
        ? math.sin(_slosh.value * math.pi * 3) * (1 - _slosh.value)
        : 0.0;

    return GestureDetector(
      onTap: () => _showXPHistory(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          key: _cardKey,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    key: _levelKey,
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          kPBlue.withOpacity(0.25),
                          kPBlue.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: kPBlue.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$level',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kPBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Level $level',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kPTextPri,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '-> ${level + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kPTextSec,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fmtXp(xpShown)} / ${fmtXp(nextAt)} XP  ·  ${fmtXp(remaining < 0 ? 0 : remaining)} to go',
                          style: const TextStyle(
                            fontSize: 10,
                            color: kPTextSec,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kPTextSec,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.history, size: 14, color: kPTextSec),
                ],
              ),
              SizedBox(height: _rushing ? 9 : 12),
              Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.diagonal3Values(1, 1 + .35 * sloshK, 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: _rushing ? 14 : 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: sloshK.abs() > .01
                        ? [
                            BoxShadow(
                                color: kPPurple.withValues(
                                    alpha: .6 * sloshK.abs()),
                                blurRadius: 24)
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: kPSurface2),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient:
                                  LinearGradient(colors: [kPBlue, kPPurple]),
                            ),
                          ),
                        ),
                        if (_rushing)
                          Align(
                            alignment:
                                Alignment(pct.clamp(0.0, 1.0) * 2 - 1, 0),
                            child: AnimatedBuilder(
                              animation: _wave,
                              builder: (_, __) => CustomPaint(
                                size: const Size(8, 14),
                                painter: _WaveEdgePainter(_wave.value),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileStatsSection extends StatelessWidget {
  final List<StatData> stats;
  final int availablePoints;

  const ProfileStatsSection({
    super.key,
    required this.stats,
    required this.availablePoints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availablePoints > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.blue.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIconImage(
                    AppIcons.rewardGrantItem,
                    size: 15,
                    visualScale: 1.35,
                  ),
                  const SizedBox(width: 8),
                  FlipSwap(
                    value: availablePoints,
                    child: Text(
                      '$availablePoints',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                  Text(
                    ' stat point${availablePoints == 1 ? '' : 's'} available — tap + to spend',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'CORE STATS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kPTextSec,
              letterSpacing: 0.7,
            ),
          ),
        ),
        for (final stat in stats) ...[
          ProfileStatCard(stat: stat, availablePoints: availablePoints),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class ProfileStatCard extends ConsumerStatefulWidget {
  final StatData stat;
  final int availablePoints;

  const ProfileStatCard({
    super.key,
    required this.stat,
    required this.availablePoints,
  });

  @override
  ConsumerState<ProfileStatCard> createState() => _ProfileStatCardState();
}

class _ProfileStatCardState extends ConsumerState<ProfileStatCard>
    with SingleTickerProviderStateMixin {
  bool _spending = false;

  // "Gauge tick": when the value rises the bar steps forward with a glow,
  // the number slides up to its new value and a +N rune floats above it.
  late final AnimationController _tick = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..addListener(() => setState(() {}));
  final _valueKey = GlobalKey();

  @override
  void didUpdateWidget(ProfileStatCard old) {
    super.didUpdateWidget(old);
    final gained = widget.stat.value - old.stat.value;
    if (old.stat.key != widget.stat.key || gained <= 0) return;
    if (!RewardFx.enabled(context)) return;
    _tick.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = RewardFx.centerOf(_valueKey);
      if (p == null) return;
      RewardFx.floatText(
          context, p + const Offset(0, -14), '+$gained', widget.stat.color,
          rise: 22, duration: const Duration(milliseconds: 1000));
    });
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  void _showDetail(BuildContext context) {
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

  Future<void> _spendPoint() async {
    setState(() => _spending = true);
    try {
      await ref
          .read(characterProfileProvider.notifier)
          .spendStatPoint(widget.stat.key);
    } catch (_) {
      // Keep silent; the provider refresh remains the source of truth.
    } finally {
      if (mounted) setState(() => _spending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.stat.value / 100.0).clamp(0.0, 1.0);
    final hasPoints = widget.availablePoints > 0;
    final glow = _tick.isAnimating
        ? (_tick.value < .4 ? _tick.value / .4 : 1 - (_tick.value - .4) / .6)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: kPSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasPoints ? widget.stat.color.withOpacity(0.5) : kPBorder,
            ),
            boxShadow: glow > 0
                ? [
                    BoxShadow(
                        color: widget.stat.color.withValues(alpha: .4 * glow),
                        blurRadius: 16)
                  ]
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: AppIconImage(widget.stat.iconAsset, size: 26),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 34,
                child: Text(
                  widget.stat.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kPTextPri,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(height: 5, color: kPSurface2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: pct),
                        duration: AppMotion.duration(
                            context, const Duration(milliseconds: 600)),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => FractionallySizedBox(
                          widthFactor: v,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                  widget.stat.color, Colors.white, .45 * glow),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.stat.color
                                      .withOpacity(0.5 + .5 * glow),
                                  blurRadius: 6 + 10 * glow,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyedSubtree(
                    key: _valueKey,
                    child: SlotNumber(
                      '${widget.stat.value}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.stat.color,
                      ),
                    ),
                  ),
                  if (widget.stat.gearBonus > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.green.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        '+${widget.stat.gearBonus}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasPoints) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _spending ? null : _spendPoint,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: widget.stat.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.stat.color.withOpacity(0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.stat.color.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: _spending
                        ? Padding(
                            padding: const EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.stat.color,
                            ),
                          )
                        : Icon(
                            Icons.add,
                            size: 16,
                            color: widget.stat.color,
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileActivitySummary extends StatelessWidget {
  final CharacterProfile profile;

  const ProfileActivitySummary({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'THIS WEEK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kPTextSec,
              letterSpacing: 0.7,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(width: 0),
              ProfileMiniCard(
                iconAsset: AppIcons.activityRunning,
                emoji: '🏃',
                label: 'Runs',
                value: '${profile.weeklyRuns}',
                sub: 'this week',
              ),
              const SizedBox(width: 10),
              ProfileMiniCard(
                iconAsset: AppIcons.mapCurrentLocation,
                emoji: '📏',
                label: 'Distance',
                value: '${profile.weeklyDistanceKm.toStringAsFixed(1)} km',
                sub: 'total',
              ),
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showStreakDetailSheet(context),
                child: ProfileMiniCard(
                  iconAsset: AppIcons.rewardStreakFire,
                  emoji: '🔥',
                  label: 'Streak',
                  value: '${profile.currentStreak} days',
                  sub: 'current',
                ),
              ),
              const SizedBox(width: 10),
              ProfileMiniCard(
                iconAsset: AppIcons.rewardXpSparkle,
                emoji: '⚡',
                label: 'XP Earned',
                value: fmtXp(profile.weeklyXpEarned),
                sub: 'this week',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TalentBonusSection extends StatelessWidget {
  final TalentSummary talents;
  const _TalentBonusSection({required this.talents});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 15, color: AppColors.purple),
              const SizedBox(width: 6),
              Text(
                'TALENT BONUSES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${talents.ownedCount}/${talents.catalogCount} owned · ${talents.totalLevels} lv',
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final line in talents.effectLines)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    line,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wavy leading edge painted on the XP bar while it fills.
class _WaveEdgePainter extends CustomPainter {
  final double phase;
  _WaveEdgePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, 0);
    const waves = 2.0;
    for (var y = 0.0; y <= size.height; y += 1) {
      final x = size.width *
          (.5 + .5 * math.sin((y / size.height * waves + phase) * 2 * math.pi));
      path.lineTo(x, y);
    }
    path
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE0B8FF));
  }

  @override
  bool shouldRepaint(_WaveEdgePainter old) => old.phase != phase;
}
