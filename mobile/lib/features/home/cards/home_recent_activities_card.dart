import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../activity/models/activity_models.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/tracking/tracked_session_models.dart';
import '../../activity/tracking/workout_tracker.dart';

/// Shows the full activity-history sheet — the "workout journal". Used by
/// the Adventure Hub's Journal tile.
void showActivityJournalSheet(BuildContext context) {
  showAppBottomSheet(
    context: context,
    useRootNavigator: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AllActivitiesSheet(),
  );
}

class _ActivityRow extends StatelessWidget {
  final ActivityHistoryDto activity;
  final bool isLast;

  const _ActivityRow({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final at = activity.activityType;
    final iconAsset = at?.iconAsset ?? AppIcons.activityRunning;
    final name = at?.displayName ?? activity.type;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  border:
                      Border.all(color: AppColors.green.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: AppIconImage(iconAsset, size: 34)),
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
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
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
    if (activity.distanceKm > 0) {
      parts.add('${activity.distanceKm.toStringAsFixed(1)} km');
    }
    if (activity.calories > 0) {
      parts.add('${activity.calories} kcal');
    }
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

// ── Full-list modal sheet ─────────────────────────────────────────────────────

class _AllActivitiesSheet extends ConsumerWidget {
  const _AllActivitiesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(activityHistoryProvider);
    final sessionsAsync = ref.watch(trackedSessionsProvider);
    final tracker = ref.watch(workoutTrackerProvider);
    final history = historyAsync.valueOrNull ?? const <ActivityHistoryDto>[];
    final remoteSessions =
        sessionsAsync.valueOrNull ?? const <TrackedSessionDto>[];
    final remoteIds =
        remoteSessions.map((session) => session.sessionId).toSet();
    final pending = tracker.pendingSessions
        .where((session) => !remoteIds.contains(session.id))
        .toList();
    final entries = <({DateTime at, Widget child})>[
      for (final session in pending)
        (
          at: session.endedAt ?? session.startedAt,
          child: ListTile(
            onTap: tracker.retryPending,
            leading:
                Text(session.type.emoji, style: const TextStyle(fontSize: 26)),
            title: Text(session.type.displayName,
                style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(
              '${(session.accumulatedSeconds / 60).ceil()} min · '
              '${(session.distanceMeters / 1000).toStringAsFixed(2)} km · '
              'Saved on phone',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: const Tooltip(
              message: 'Tap to retry sync',
              child: Icon(Icons.cloud_upload_outlined, color: AppColors.blue),
            ),
          ),
        ),
      for (final session in remoteSessions)
        if (session.rewardedActivityId == null)
          (
            at: session.endedAt,
            child: ListTile(
              leading: Text(session.type.emoji,
                  style: const TextStyle(fontSize: 26)),
              title: Text(session.type.displayName,
                  style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(
                '${(session.activeSeconds / 60).ceil()} min · '
                '${(session.distanceMeters / 1000).toStringAsFixed(2)} km · '
                '${session.endedAt.toLocal().day}/${session.endedAt.toLocal().month}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Text('No rewards',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
      for (final activity in history)
        (
          at: activity.loggedAt,
          child: _ActivityRow(activity: activity, isLast: true),
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

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
          if (pending.isNotEmpty && tracker.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(tracker.error!,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          Expanded(
            child: entries.isNotEmpty
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (_, i) => entries[i].child,
                  )
                : historyAsync.isLoading || sessionsAsync.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : historyAsync.hasError || sessionsAsync.hasError
                        ? Center(
                            child: TextButton(
                              onPressed: () {
                                ref.invalidate(activityHistoryProvider);
                                ref.invalidate(trackedSessionsProvider);
                              },
                              child: const Text(
                                  'Could not load activities. Retry'),
                            ),
                          )
                        : const Center(
                            child: Text(
                              'No activities yet. Start your first workout!',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
