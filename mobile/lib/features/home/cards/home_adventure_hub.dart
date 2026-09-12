import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/providers/character_provider.dart';
import '../../guild/screens/guild_screen.dart';
import '../../login_reward/login_reward_screen.dart';
import '../../quests/quests_screen.dart';
import '../../streak/widgets/streak_detail_sheet.dart';
import '../../titles/titles_ranks_screen.dart';
import 'home_recent_activities_card.dart' show showActivityJournalSheet;

/// Horizontally-scrollable row of quick entry points into the game's
/// systems — daily rewards, streak, workout journal, guild challenges, and
/// titles/ranks — matching the "Adventure Hub" reference layout. Sits right
/// under the hero-stage card.
class HomeAdventureHub extends ConsumerWidget {
  const HomeAdventureHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;
    final rewardAvailable = profile?.loginRewardAvailable ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ADVENTURE HUB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Swipe for more',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HubTile(
                  icon: AppIconImage(AppIcons.rewardDailyBonus, size: 30),
                  label: 'Rewards',
                  showBadge: rewardAvailable,
                  onTap: () => _openRewards(context),
                ),
                const SizedBox(width: 10),
                _HubTile(
                  icon: AppIconImage(AppIcons.rewardStreakFire, size: 30),
                  label: 'Streak',
                  onTap: () => showStreakDetailSheet(context),
                ),
                const SizedBox(width: 10),
                _HubTile(
                  icon: AppIconImage(AppIcons.homeJournalIcon, size: 30),
                  label: 'Journal',
                  onTap: () => showActivityJournalSheet(context),
                ),
                const SizedBox(width: 10),
                _HubTile(
                  icon: AppIconImage(AppIcons.navQuests, size: 30),
                  label: 'Quests',
                  onTap: () => _openQuests(context),
                ),
                const SizedBox(width: 10),
                _HubTile(
                  icon: AppIconImage(AppIcons.ringGuild, size: 30),
                  label: 'Challenges',
                  onTap: () => _openGuild(context),
                ),
                const SizedBox(width: 10),
                _HubTile(
                  icon: AppIconImage(AppIcons.ringTitles, size: 30),
                  label: 'Milestones',
                  onTap: () => _openTitles(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openRewards(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (ctx) => LoginRewardScreen(
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openQuests(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuestsScreen()),
    );
  }

  void _openGuild(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => GuildScreen(onClose: () => Navigator.of(ctx).pop()),
      ),
    );
  }

  void _openTitles(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>
            TitlesRanksScreen(onClose: () => Navigator.of(ctx).pop()),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool showBadge;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.label,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: icon),
                ),
                if (showBadge)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.red,
                        border:
                            Border.all(color: AppColors.backgroundAlt, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '!',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
