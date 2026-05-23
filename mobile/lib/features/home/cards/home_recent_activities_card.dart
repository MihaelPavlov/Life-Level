import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../activity/models/activity_models.dart';
import '../../activity/providers/activity_provider.dart';
import '../widgets/home_card.dart';
import '../widgets/home_section_title.dart';

class HomeRecentActivitiesCard extends ConsumerWidget {
  const HomeRecentActivitiesCard({super.key});

  void _showAll(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AllActivitiesSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(activityHistoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: HomeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionTitle(
              label: 'RECENT ACTIVITIES',
              action: 'See all →',
              onActionTap: () => _showAll(context),
            ),
            historyAsync.when(
              loading: () => const _LoadingRows(),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Failed to load activities.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.invalidate(activityHistoryProvider),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (history) {
                if (history.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No activities yet. Log your first workout!',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  );
                }
                final preview = history.take(3).toList();
                return Column(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      _ActivityRow(
                        activity: preview[i],
                        isLast: i == preview.length - 1,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityHistoryDto activity;
  final bool isLast;

  const _ActivityRow({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final at = activity.activityType;
    final emoji = at?.emoji ?? '🏃';
    final name = at?.displayName ?? activity.type;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subLine(),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${activity.xpGained} XP',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _timeAgo(activity.loggedAt),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: AppColors.border.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  String _subLine() {
    final parts = ['${activity.durationMinutes} min'];
    if (activity.distanceKm > 0) parts.add('${activity.distanceKm.toStringAsFixed(1)} km');
    if (activity.calories > 0) parts.add('${activity.calories} kcal');
    return parts.join(' · ');
  }

  String _timeAgo(DateTime loggedAt) {
    final now = DateTime.now().toUtc();
    final utc = loggedAt.isUtc ? loggedAt : loggedAt.toUtc();
    final diff = now.difference(utc);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${utc.day}/${utc.month}';
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

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
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ── Full-list modal sheet ─────────────────────────────────────────────────────

class _AllActivitiesSheet extends ConsumerWidget {
  const _AllActivitiesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(activityHistoryProvider);

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: Color(0xFF0d1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to load activities.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(activityHistoryProvider),
                      child: const Text('Retry',
                          style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              data: (history) {
                if (history.isEmpty) {
                  return const Center(
                    child: Text(
                      'No activities yet. Log your first workout!',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (_, i) => _ActivityRow(
                    activity: history[i],
                    isLast: i == history.length - 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
