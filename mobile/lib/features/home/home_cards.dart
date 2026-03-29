import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/level_up_overlay.dart';
import '../activity/log_activity_screen.dart';
import '../character/models/character_profile.dart';
import '../character/providers/character_provider.dart';
import '../quests/models/quest_models.dart'
    show UserQuestProgress, questCategoryEmoji, questCategoryColor;
import '../quests/providers/quest_provider.dart';
import '../streak/providers/streak_provider.dart';
import 'home_widgets.dart';

// ── HEADER ──────────────────────────────────────────────────────────────────────
class HomeHeader extends StatelessWidget {
  final CharacterProfile? profile;

  const HomeHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left: greeting + name + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning 👋',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  profile?.username ?? '...',
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  children: [
                    HomeBadge('LV ${profile?.level ?? '?'}', AppColors.blue),
                    if (profile != null) HomeBadge(profile!.rank.toUpperCase(), AppColors.purple),
                    if (profile?.className != null) HomeBadge(profile!.className!.toUpperCase(), AppColors.orange),
                  ],
                ),
              ],
            ),
          ),
          // right: avatar + tappable LV badge + notification dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              // avatar circle
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.blue, AppColors.purple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.35),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(profile?.avatarEmoji ?? '🏃', style: const TextStyle(fontSize: 24)),
                ),
              ),
              // tappable LV badge — pulsing hint
              Positioned(
                bottom: -4,
                left: 0, right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => showLevelUpScreen(context, profile?.level ?? 1),
                    child: HomePulsingLvBadge(label: 'LV ${profile?.level ?? '?'}'),
                  ),
                ),
              ),
              // notification dot
              Positioned(
                top: -2, right: -2,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: kHBgBase, width: 2),
                  ),
                  child: const Center(
                    child: Text('3',
                        style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── XP PROGRESS CARD ────────────────────────────────────────────────────────────
class HomeXpCard extends StatelessWidget {
  final CharacterProfile? profile;

  const HomeXpCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final progress = p?.xpProgress ?? 0.0;
    final pct = '${(progress * 100).round()}%';
    return HomeCard(
      borderColor: AppColors.blue.withValues(alpha: 0.28),
      glowColor: AppColors.blue.withValues(alpha: 0.07),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p != null ? 'Level ${p.level}' : '...',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(p != null ? '${homeFmt(p.xp)} / ${homeFmt(p.xpForNextLevel)} XP' : '...',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(p != null ? 'Level ${p.level + 1}' : '...',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          HomeProgressBar(progress: progress, colors: [AppColors.blue, AppColors.purple], height: 10),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p != null ? '${homeFmt(p.xpRemaining)} XP to next level' : '...',
                  style: const TextStyle(fontSize: 10, color: kHTextMuted)),
              Text(pct,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.blue)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── STREAK CARD ──────────────────────────────────────────────────────────────────
class HomeStreakCard extends ConsumerWidget {
  const HomeStreakCard({super.key});

  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final streakAsync = ref.watch(streakProvider);
    final streakData = streakAsync.valueOrNull;

    final currentStreak = profile?.currentStreak ?? streakData?.current ?? 0;
    final longestStreak = streakData?.longest ?? 0;
    final shields = streakData?.shieldsAvailable ?? 0;

    // Build 7-day grid: last `currentStreak` days are filled (capped at 7),
    // today is the rightmost slot if streak > 0.
    final today = DateTime.now();
    final dayIndex = today.weekday - 1; // 0 = Mon, 6 = Sun

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStreak == 1
                          ? '1-Day Streak'
                          : '$currentStreak-Day Streak',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      longestStreak > 0
                          ? 'Best: $longestStreak days'
                          : 'Keep it going!',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (shields > 0)
                HomeBadge('🛡 $shields Shield${shields > 1 ? 's' : ''}', AppColors.green, fontSize: 9),
            ],
          ),
          const SizedBox(height: 10),
          // 7-day grid: Mon–Sun
          Row(
            children: List.generate(7, (i) {
              // How many days ago is index i (0=Mon)?
              // Days before today in the week are index 0..(dayIndex-1),
              // today is dayIndex, days after today are dayIndex+1..6.
              final daysAgo = dayIndex - i;
              final isToday = i == dayIndex;
              final isFuture = i > dayIndex;

              // A past day is "done" if the streak covers it.
              // streak=1 means only today is active.
              // streak=5 means today + 4 prior days.
              final isDone = !isFuture && !isToday && daysAgo <= currentStreak - 1;

              HomeStreakState state;
              String icon;
              if (isToday && currentStreak > 0) {
                state = HomeStreakState.today;
                icon = '🔥';
              } else if (isDone) {
                state = HomeStreakState.done;
                icon = '✓';
              } else {
                state = HomeStreakState.next;
                icon = '·';
              }

              return [
                Expanded(
                  child: HomeStreakDay(
                    icon: icon,
                    label: _dayLabels[i],
                    state: state,
                  ),
                ),
                if (i < 6) const SizedBox(width: 5),
              ];
            }).expand((w) => w).toList(),
          ),
          // Use Shield button
          if (shields > 0) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _useShield(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('🛡️', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      'Use Shield to protect streak',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _useShield(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(streakProvider.notifier).useShield();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor:
                result.success ? AppColors.green : AppColors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to use shield: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}

// ── DAILY QUESTS CARD ────────────────────────────────────────────────────────────
class HomeQuestsCard extends ConsumerWidget {
  const HomeQuestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(dailyQuestsProvider);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          questsAsync.when(
            loading: () => HomeSectionTitle(
              label: 'DAILY QUESTS',
              action: 'Loading...',
            ),
            error: (_, __) => HomeSectionTitle(
              label: 'DAILY QUESTS',
              action: 'Tap to retry',
              actionColor: AppColors.red,
            ),
            data: (quests) {
              final completed = quests.where((q) => q.isCompleted).length;
              final total = quests.isEmpty ? 5 : quests.length;
              return HomeSectionTitle(
                label: 'DAILY QUESTS',
                action: '$completed / $total done',
              );
            },
          ),
          questsAsync.when(
            loading: () => const _QuestLoadingRows(),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: () => ref.read(dailyQuestsProvider.notifier).refresh(),
                child: const Text(
                  'Failed to load. Tap to retry.',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            data: (quests) {
              if (quests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No daily quests available.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                );
              }
              // Show up to 3 quests in the card.
              final preview = quests.take(3).toList();
              return Column(
                children: preview.map((q) {
                  final iconState = q.isCompleted
                      ? HomeQuestState.done
                      : q.progress > 0
                          ? HomeQuestState.active
                          : HomeQuestState.pending;
                  final progressColor = _categoryColor(q.category);
                  return HomeQuestItem(
                    icon: _categoryEmoji(q.category),
                    iconState: iconState,
                    name: q.title,
                    sub: _progressSub(q),
                    xp: '+${q.rewardXp} XP',
                    done: q.isCompleted,
                    progress: q.isCompleted ? null : q.progress,
                    progressColor: progressColor,
                  );
                }).toList(),
              );
            },
          ),
          // "See all" link when there are more than 3 quests
          questsAsync.whenOrNull(
            data: (quests) {
              if (quests.length <= 3) return null;
              final remaining = quests.length - 3;
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: GestureDetector(
                  onTap: () {
                    // The shell handles navigation — navigate by switching tab.
                    // Fallback: do nothing. The user can tap the Quests tab.
                  },
                  child: Text(
                    '+$remaining more — See all →',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.06),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Complete all quests',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('+300 Bonus XP',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryEmoji(String category) => questCategoryEmoji(category);

  Color _categoryColor(String category) => questCategoryColor(category);

  String _progressSub(UserQuestProgress q) {
    final cur = q.targetUnit == 'km'
        ? q.currentValue.toStringAsFixed(1)
        : q.currentValue.toInt().toString();
    final tgt = q.targetUnit == 'km'
        ? q.targetValue.toStringAsFixed(1)
        : q.targetValue.toInt().toString();
    if (q.isCompleted) return 'Completed';
    return '$cur / $tgt ${q.targetUnit}';
  }
}

// Loading placeholder rows
class _QuestLoadingRows extends StatelessWidget {
  const _QuestLoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 38,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

// ── LAST ACTIVITY CARD ────────────────────────────────────────────────────────────
class HomeLastActivityCard extends StatelessWidget {
  const HomeLastActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      borderColor: AppColors.green.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            label: 'LAST ACTIVITY',
            action: '2 hours ago',
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                    child: Text('🏃', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Morning Run',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '5.2 km · 28:14 · Avg 5:26/km · 156 bpm',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        HomeGainChip(label: '+450 XP', color: AppColors.orange),
                        HomeGainChip(label: '+2 END', color: AppColors.green),
                        HomeGainChip(label: '+2 AGI', color: AppColors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Log Activity button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LogActivityScreen(),
                fullscreenDialog: true,
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💪', style: TextStyle(fontSize: 15)),
                  SizedBox(width: 6),
                  Text(
                    'Log Activity',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CHARACTER STATS ROW ───────────────────────────────────────────────────────────
class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(label: 'CHARACTER STATS'),
          Row(
            children: [
              HomeStatGem(value: '84', label: 'STR', color: AppColors.red),
              const SizedBox(width: 6),
              HomeStatGem(value: '71', label: 'END', color: AppColors.green),
              const SizedBox(width: 6),
              HomeStatGem(value: '92', label: 'AGI', color: AppColors.blue),
              const SizedBox(width: 6),
              HomeStatGem(value: '65', label: 'FLX', color: AppColors.purple),
              const SizedBox(width: 6),
              HomeStatGem(value: '78', label: 'STA', color: AppColors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

// ── BOSS CARD ──────────────────────────────────────────────────────────────────────
class HomeBossCard extends StatelessWidget {
  const HomeBossCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      borderColor: AppColors.red.withValues(alpha: 0.28),
      glowColor: AppColors.red.withValues(alpha: 0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            label: 'ACTIVE BOSS',
            action: 'Fight now →',
            actionColor: AppColors.red,
          ),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🗻', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Iron Peak Mountain',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('⏰ 4d 12h remaining',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red)),
                  const SizedBox(height: 1),
                  Text('HP: 8,420 / 12,000 · Veteran difficulty',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('8,420 HP remaining',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('70%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red)),
            ],
          ),
          const SizedBox(height: 4),
          HomeProgressBar(progress: 0.70, colors: [AppColors.red, AppColors.redDark]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              HomeBadge('🗡 You dealt 1,240 dmg', AppColors.red, fontSize: 9),
              HomeBadge('+180 dmg / session', AppColors.orange, fontSize: 9),
            ],
          ),
        ],
      ),
    );
  }
}
