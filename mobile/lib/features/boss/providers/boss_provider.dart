import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/boss_damage_history.dart';
import '../services/boss_page_service.dart';
import '../models/boss_list_item.dart';

final bossPageServiceProvider =
    Provider<BossPageService>((ref) => BossPageService());

class BossListNotifier extends AsyncNotifier<List<BossListItem>> {
  @override
  Future<List<BossListItem>> build() =>
      ref.watch(bossPageServiceProvider).getAllBosses();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(bossPageServiceProvider).getAllBosses(),
    );
  }
}

final bossListProvider =
    AsyncNotifierProvider<BossListNotifier, List<BossListItem>>(
  BossListNotifier.new,
);

/// Per-activity damage rows for a single boss's active fight. Keyed by
/// boss id. Use `ref.invalidate(bossDamageHistoryProvider(bossId))` to
/// force a refetch (e.g. after the user logs a workout and returns to the
/// battle screen).
final bossDamageHistoryProvider = FutureProvider.family<
    List<BossDamageHistoryItem>, String>(
  (ref, bossId) =>
      ref.watch(bossPageServiceProvider).getDamageHistory(bossId),
);
