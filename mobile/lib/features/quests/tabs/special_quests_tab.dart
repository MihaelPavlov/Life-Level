import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/quest_provider.dart';
import '../widgets/quest_card.dart';
import '../widgets/quest_shimmer.dart';
import '../widgets/quest_empty_state.dart';
import '../widgets/quest_error_state.dart';

class SpecialQuestsTab extends ConsumerWidget {
  const SpecialQuestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(specialQuestsProvider);
    return questsAsync.when(
      loading: () => const QuestShimmer(),
      error: (e, _) => QuestErrorState(
        message: 'Failed to load special quests',
        onRetry: () => ref.invalidate(specialQuestsProvider),
      ),
      data: (quests) => quests.isEmpty
          ? const QuestEmptyState(
              'Special quests unlock as you level up and explore new zones')
          : RefreshIndicator(
              color: AppColors.blue,
              backgroundColor: AppColors.surface,
              onRefresh: () async => ref.invalidate(specialQuestsProvider),
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
