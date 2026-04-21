import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../character/models/character_profile.dart';
import '../character/providers/character_provider.dart';
import 'profile_stat_metadata.dart';
import 'profile_widgets.dart';
import 'xp_history_sheet.dart';
import 'stat_detail_sheet.dart';
import '../streak/widgets/streak_detail_sheet.dart';

// ── ProfileOverviewTab ────────────────────────────────────────────────────────
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
        const SizedBox(height: 20),
        ProfileActivitySummary(profile: profile),
      ],
    );
  }
}

// ── ProfileXpSection ──────────────────────────────────────────────────────────
class ProfileXpSection extends StatelessWidget {
  final CharacterProfile profile;
  const ProfileXpSection({super.key, required this.profile});

  static void _showXPHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const XpHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = profile.xpProgress;
    final remaining = profile.xpRemaining;

    return GestureDetector(
      onTap: () => _showXPHistory(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // level + xp label row
              Row(
                children: [
                  // level circle
                  Container(
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
                      border: Border.all(color: kPBlue.withOpacity(0.5), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${profile.level}',
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
                              'Level ${profile.level}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kPTextPri,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '→ ${profile.level + 1}',
                              style: const TextStyle(fontSize: 12, color: kPTextSec),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fmtXp(profile.xp)} / ${fmtXp(profile.xpForNextLevel)} XP  ·  ${fmtXp(remaining < 0 ? 0 : remaining)} to go',
                          style: const TextStyle(fontSize: 10, color: kPTextSec),
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

              const SizedBox(height: 12),

              // XP bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(height: 8, color: kPSurface2),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPBlue, kPPurple],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ProfileStatsSection ───────────────────────────────────────────────────────
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
                  const Text('✨', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    '$availablePoints stat point${availablePoints == 1 ? '' : 's'} available — tap + to spend',
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

// ── ProfileStatCard ───────────────────────────────────────────────────────────
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

class _ProfileStatCardState extends ConsumerState<ProfileStatCard> {
  bool _spending = false;

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
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
      await ref.read(characterProfileProvider.notifier).spendStatPoint(widget.stat.key);
    } catch (_) {
      // silently fail — provider will not refresh on error
    } finally {
      if (mounted) setState(() => _spending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.stat.value / 100.0).clamp(0.0, 1.0);
    final hasPoints = widget.availablePoints > 0;

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
          ),
          child: Row(
            children: [
              // emoji icon
              SizedBox(
                width: 32,
                child: Text(widget.stat.emoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),

              // stat key
              SizedBox(
                width: 34,
                child: Text(widget.stat.key,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: kPTextPri)),
              ),

              // bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(children: [
                    Container(height: 5, color: kPSurface2),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: widget.stat.color,
                          boxShadow: [
                            BoxShadow(
                              color: widget.stat.color.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(width: 10),

              // value (base + optional gear bonus chip)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${widget.stat.value}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.stat.color)),
                  if (widget.stat.gearBonus > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.green.withOpacity(0.4)),
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

              // + button — only when points available
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
                      border: Border.all(color: widget.stat.color.withOpacity(0.6)),
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
                                strokeWidth: 2, color: widget.stat.color),
                          )
                        : Icon(Icons.add, size: 16, color: widget.stat.color),
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

// ── ProfileActivitySummary ────────────────────────────────────────────────────
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
              ProfileMiniCard(
                emoji: '🏃',
                label: 'Runs',
                value: '${profile.weeklyRuns}',
                sub: 'this week',
              ),
              const SizedBox(width: 10),
              ProfileMiniCard(
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
                  emoji: '🔥',
                  label: 'Streak',
                  value: '${profile.currentStreak} days',
                  sub: 'current',
                ),
              ),
              const SizedBox(width: 10),
              ProfileMiniCard(
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
