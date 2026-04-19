import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/deep_link_notifier.dart';
import '../models/notification_list_models.dart';
import '../providers/notification_list_provider.dart';
import 'notification_row.dart';

/// Shows the notifications bottom sheet. Dim backdrop + drag-to-dismiss +
/// "Mark all read" action. Matches screen 4 of home-v3.html.
///
/// Each row deep-links via [DeepLinkNotifier] so navigation reuses the same
/// pathway as FCM taps and OAuth callbacks.
Future<void> showNotificationsSheet(BuildContext context) {
  // Trigger a refresh every time the sheet opens so badge + list stay in sync.
  final container = ProviderScope.containerOf(context, listen: false);
  unawaitedSafely(
    container.read(notificationListProvider.notifier).refresh(),
  );

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xA6040810), // matches .home3-backdrop rgba
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _NotificationsSheet(),
  );
}

/// Wrapper so we never surface an unawaited-future lint in callers.
void unawaitedSafely(Future<void> future) {
  future.catchError((_) {/* swallow */});
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(notificationListProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 40,
                offset: Offset(0, -18),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header row
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(notificationListProvider.notifier)
                          .markAllRead(),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Body
              Expanded(
                child: listAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(
                        color: AppColors.blue,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (_, __) => _ErrorView(
                    onRetry: () => ref
                        .read(notificationListProvider.notifier)
                        .refresh(),
                  ),
                  data: (items) {
                    if (items.isEmpty) return const _EmptyView();
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.surfaceElevated,
                      ),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return NotificationRow(
                          item: item,
                          onTap: () => _handleTap(context, item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, NotificationItem item) {
    final link = item.deepLink;
    Navigator.of(context).maybePop();
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri != null) DeepLinkNotifier.notify(uri);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\uD83D\uDD14', style: TextStyle(fontSize: 36)),
            SizedBox(height: 12),
            Text(
              'You\u2019re all caught up',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Nothing new right now. We\u2019ll let you know when the next raid, storm, or quest kicks off.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Couldn\u2019t load notifications.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
