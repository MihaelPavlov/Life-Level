import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_list_models.dart';
import '../services/notification_list_service.dart';

final notificationListServiceProvider = Provider<NotificationListService>(
  (ref) => NotificationListService(),
);

/// Notifier that owns the bell-sheet list. Kept as a mutable list so the
/// sheet can optimistically flip every row to "read" when the user hits
/// "Mark all read" without waiting on the server round-trip.
class NotificationListNotifier extends AsyncNotifier<List<NotificationItem>> {
  @override
  Future<List<NotificationItem>> build() =>
      ref.read(notificationListServiceProvider).list();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(notificationListServiceProvider).list(),
    );
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current.map((n) => n.copyWith(isRead: true)).toList(),
      );
    }
    try {
      await ref.read(notificationListServiceProvider).markAllRead();
    } catch (_) {
      // If the server call fails we still keep the optimistic update; a
      // refresh on next sheet open will reconcile.
    }
  }
}

final notificationListProvider =
    AsyncNotifierProvider<NotificationListNotifier, List<NotificationItem>>(
  NotificationListNotifier.new,
);

/// Exposes only the unread count so the bell badge does not rebuild when
/// a row body (title/sub) changes.
final notificationUnreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationListProvider).valueOrNull;
  if (list == null) return 0;
  return list.where((n) => !n.isRead).length;
});
