import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/talent_models.dart';
import '../services/talents_service.dart';

final talentsServiceProvider =
    Provider<TalentsService>((ref) => TalentsService());

class TalentsNotifier extends AsyncNotifier<TalentScreen> {
  @override
  Future<TalentScreen> build() => ref.watch(talentsServiceProvider).getScreen();

  Future<TalentDrawResult> draw() async {
    final result = await ref.read(talentsServiceProvider).draw();
    ref.invalidateSelf();
    return result;
  }

  Future<TalentUpgradeResult> upgrade(String key) async {
    final result = await ref.read(talentsServiceProvider).upgrade(key);
    ref.invalidateSelf();
    return result;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(talentsServiceProvider).getScreen(),
    );
  }
}

final talentsProvider =
    AsyncNotifierProvider<TalentsNotifier, TalentScreen>(TalentsNotifier.new);
