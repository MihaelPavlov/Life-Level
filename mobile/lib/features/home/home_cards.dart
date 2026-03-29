import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/level_up_overlay.dart';
import '../character/models/character_profile.dart';
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
                Text(
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
class HomeStreakCard extends StatelessWidget {
  const HomeStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('14-Day Streak',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Reward in 7 days — ×1.5 XP bonus',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              HomeBadge('🛡 Shield ready', AppColors.green, fontSize: 9),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              HomeStreakDay(icon: '✓',  label: 'MON',   state: HomeStreakState.done),
              const SizedBox(width: 5),
              HomeStreakDay(icon: '✓',  label: 'TUE',   state: HomeStreakState.done),
              const SizedBox(width: 5),
              HomeStreakDay(icon: '✓',  label: 'WED',   state: HomeStreakState.done),
              const SizedBox(width: 5),
              HomeStreakDay(icon: '✓',  label: 'THU',   state: HomeStreakState.done),
              const SizedBox(width: 5),
              HomeStreakDay(icon: '✓',  label: 'FRI',   state: HomeStreakState.done),
              const SizedBox(width: 5),
              HomeStreakDay(icon: '✓',  label: 'SAT',   state: HomeStreakState.done),
              const SizedBox(width: 5),
              HomeStreakDay(icon: '🔥', label: 'TODAY', state: HomeStreakState.today),
            ],
          ),
        ],
      ),
    );
  }
}

// ── DAILY QUESTS CARD ────────────────────────────────────────────────────────────
class HomeQuestsCard extends StatelessWidget {
  const HomeQuestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(label: 'DAILY QUESTS', action: '3 / 5 done · resets 12h'),
          HomeQuestItem(
            icon: '🏃', iconState: HomeQuestState.done,
            name: 'Run 30 minutes', sub: '32 min completed',
            xp: '+150 XP', done: true,
          ),
          HomeQuestItem(
            icon: '🔥', iconState: HomeQuestState.done,
            name: 'Burn 300 calories', sub: '348 cal burned',
            xp: '+100 XP', done: true,
          ),
          HomeQuestItem(
            icon: '📍', iconState: HomeQuestState.done,
            name: 'Cover 5 km', sub: '5.2 km logged',
            xp: '+100 XP', done: true,
          ),
          HomeQuestItem(
            icon: '💪', iconState: HomeQuestState.active,
            name: 'Strength session', sub: '0 / 1 session',
            xp: '+150 XP', done: false, progress: 0.0,
            progressColor: AppColors.red,
          ),
          HomeQuestItem(
            icon: '🧘', iconState: HomeQuestState.active,
            name: '10 min yoga / stretch', sub: '0 / 10 minutes',
            xp: '+100 XP', done: false, progress: 0.0,
            progressColor: AppColors.purple,
          ),
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
                Text('Complete all 5 quests',
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
          HomeSectionTitle(label: 'LAST ACTIVITY', action: '2 hours ago'),
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(child: Text('🏃', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Morning Run',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('5.2 km · 28:14 · Avg 5:26/km · 156 bpm',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        HomeGainChip(label: '+450 XP', color: AppColors.orange),
                        HomeGainChip(label: '+2 END',  color: AppColors.green),
                        HomeGainChip(label: '+2 AGI',  color: AppColors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
          HomeProgressBar(progress: 0.70, colors: [AppColors.red, const Color(0xFFc0392b)]),
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
