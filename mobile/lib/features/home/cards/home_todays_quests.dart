import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../../quests/models/quest_models.dart';
import '../../quests/providers/quest_provider.dart';
import '../widgets/home_card.dart';
import '../widgets/home_quest_item.dart';
import '../widgets/home_section_title.dart';

/// Today's-quests preview card (3 rows + see-all + bonus hint).
/// Matches `.card` that wraps `.section-title TODAY` + `.quest-item`s in
/// home-v3.html.
class HomeTodaysQuestsCard extends ConsumerWidget {
  const HomeTodaysQuestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(dailyQuestsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: HomeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            questsAsync.when(
              loading: () => const HomeSectionTitle(label: 'TODAY'),
              error: (_, __) => HomeSectionTitle(
                label: 'TODAY',
                action: 'Tap to retry',
                actionColor: AppColors.red,
                onActionTap: () =>
                    ref.read(dailyQuestsProvider.notifier).refresh(),
              ),
              data: (quests) {
                final completed = quests.where((q) => q.isCompleted).length;
                final total = quests.isEmpty ? 5 : quests.length;
                return HomeSectionTitle(
                  label: 'TODAY',
                  labelTrailing: HomeDoneChip(
                    label: '$completed / $total DONE',
                    color: completed == total && total > 0
                        ? AppColors.green
                        : (completed > 0 ? AppColors.blue : null),
                  ),
                  action: 'See all \u2192',
                  onActionTap: () => NavTabNotifier.switchTo('quests'),
                );
              },
            ),
            questsAsync.when(
              loading: () => const _QuestLoadingRows(),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Failed to load quests.',
                  style: TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ),
              data: (quests) {
                if (quests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No daily quests available.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                final preview = quests.take(3).toList();
                return Column(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      HomeQuestItem(
                        icon: questCategoryEmoji(preview[i].category),
                        iconState: preview[i].isCompleted
                            ? HomeQuestState.done
                            : preview[i].progress > 0
                                ? HomeQuestState.active
                                : HomeQuestState.pending,
                        name: preview[i].title,
                        sub: _progressSub(preview[i]),
                        xp: '+${preview[i].rewardXp} XP',
                        done: preview[i].isCompleted,
                        progress: preview[i].isCompleted
                            ? null
                            : preview[i].progress,
                        progressColor: questCategoryColor(preview[i].category),
                        isLast: i == preview.length - 1,
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              width: double.infinity,
              child: const Text(
                'Complete all 5 quests \u2192 +300 XP bonus',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _progressSub(UserQuestProgress q) {
    if (q.isCompleted) return 'Completed';
    final cur = q.targetUnit == 'km'
        ? q.currentValue.toStringAsFixed(1)
        : q.currentValue.toInt().toString();
    final tgt = q.targetUnit == 'km'
        ? q.targetValue.toStringAsFixed(1)
        : q.targetValue.toInt().toString();
    return '$cur / $tgt ${q.targetUnit}';
  }
}

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
