import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../character/providers/character_provider.dart';
import 'providers/titles_provider.dart';
import 'widgets/titles_profile_header.dart';
import 'widgets/rank_ladder_widget.dart';
import 'widgets/title_list_item.dart';

class TitlesRanksScreen extends ConsumerWidget {
  final VoidCallback? onClose;
  const TitlesRanksScreen({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titlesAsync = ref.watch(titlesProvider);
    final profileAsync = ref.watch(characterProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom app bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: AppColors.textPrimary),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Titles & Ranks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Spacer to balance the back button width
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: titlesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.blue,
                    strokeWidth: 2,
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.red, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load titles',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              ref.read(titlesProvider.notifier).refresh(),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: AppColors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (data) {
                  final profile = profileAsync.valueOrNull;
                  final notifier = ref.read(titlesProvider.notifier);

                  return CustomScrollView(
                    slivers: [
                      // Profile header
                      SliverToBoxAdapter(
                        child: profile != null
                            ? TitlesProfileHeader(
                                data: data,
                                profile: profile,
                                onChangeTitleTap: () {
                                  // Scroll down to earned titles — tap scrolls
                                  // naturally since the section is visible in
                                  // the same view. No extra action needed.
                                },
                              )
                            : const SizedBox(height: 16),
                      ),

                      // Rank progression section label
                      const SliverToBoxAdapter(
                        child: _SectionLabel('RANK PROGRESSION'),
                      ),

                      // Rank ladder card
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: RankLadderWidget(
                              progression: data.rankProgression,
                            ),
                          ),
                        ),
                      ),

                      // Earned titles section label
                      SliverToBoxAdapter(
                        child: _SectionLabel(
                            'EARNED TITLES (${data.earnedTitles.length})'),
                      ),

                      // Earned titles list
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: TitleListItem(
                              title: data.earnedTitles[i],
                              onEquip: () =>
                                  notifier.equipTitle(data.earnedTitles[i].id),
                            ),
                          ),
                          childCount: data.earnedTitles.length,
                        ),
                      ),

                      // Locked titles section label
                      const SliverToBoxAdapter(
                        child: _SectionLabel('LOCKED TITLES'),
                      ),

                      // Locked titles list
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: TitleListItem(
                              title: data.lockedTitles[i],
                              isLocked: true,
                            ),
                          ),
                          childCount: data.lockedTitles.length,
                        ),
                      ),

                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 32),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}
