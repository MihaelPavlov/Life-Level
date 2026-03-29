import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/quest_provider.dart';
import '../widgets/quest_card.dart';
import '../widgets/quest_shimmer.dart';
import '../widgets/quest_empty_state.dart';
import '../widgets/quest_error_state.dart';

class DailyQuestsTab extends ConsumerWidget {
  const DailyQuestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(dailyQuestsProvider);
    return questsAsync.when(
      loading: () => const QuestShimmer(),
      error: (e, _) => QuestErrorState(
        message: 'Failed to load daily quests',
        onRetry: () => ref.read(dailyQuestsProvider.notifier).refresh(),
      ),
      data: (quests) => quests.isEmpty
          ? const QuestEmptyState('Daily quests will refresh at midnight')
          : RefreshIndicator(
              color: AppColors.blue,
              backgroundColor: AppColors.surface,
              onRefresh: () => ref.read(dailyQuestsProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: quests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => QuestCard(quest: quests[i]),
              ),
            ),
    );
  }
}
