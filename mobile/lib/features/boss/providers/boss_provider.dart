import 'package:flutter_riverpod/flutter_riverpod.dart';
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
