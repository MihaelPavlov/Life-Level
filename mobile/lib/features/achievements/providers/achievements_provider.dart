import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement_models.dart';
import '../services/achievements_service.dart';

final _achievementsService = AchievementsService();

// All achievements (used for overall stats header + tier counts)
final achievementsProvider =
    AsyncNotifierProvider<AchievementsNotifier, List<AchievementDto>>(
  AchievementsNotifier.new,
);

class AchievementsNotifier extends AsyncNotifier<List<AchievementDto>> {
  @override
  Future<List<AchievementDto>> build() =>
      _achievementsService.getAchievements();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _achievementsService.getAchievements());
  }
}

// Category-filtered achievements
final achievementsByCategoryProvider = AsyncNotifierProviderFamily<
    AchievementsByCategoryNotifier, List<AchievementDto>, String>(
  AchievementsByCategoryNotifier.new,
);

class AchievementsByCategoryNotifier
    extends FamilyAsyncNotifier<List<AchievementDto>, String> {
  @override
  Future<List<AchievementDto>> build(String category) =>
      _achievementsService.getAchievements(
          category: category == 'All' ? null : category);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _achievementsService.getAchievements(
        category: arg == 'All' ? null : arg));
  }
}
