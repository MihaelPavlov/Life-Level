import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../character/providers/character_provider.dart';
import '../models/achievement_models.dart';
import '../services/achievements_service.dart';
import '../../../core/state/optimistic_mutation.dart';
import '../../../core/services/client_experience_service.dart';

final _achievementsService = AchievementsService();

// All achievements (used for overall stats header + tier counts)
final achievementsProvider =
    AsyncNotifierProvider<AchievementsNotifier, List<AchievementDto>>(
  AchievementsNotifier.new,
);

class AchievementsNotifier extends AsyncNotifier<List<AchievementDto>> {
  @override
  Future<List<AchievementDto>> build() async {
    return _achievementsService.getAchievements();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state =
        await AsyncValue.guard(() => _achievementsService.getAchievements());
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
  Future<List<AchievementDto>> build(String category) => _achievementsService
      .getAchievements(category: category == 'All' ? null : category);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _achievementsService.getAchievements(
        category: arg == 'All' ? null : arg));
  }
}

// ── Reward Roads ─────────────────────────────────────────────────────────────

/// Roads + wallet for the Reward Roads hub and road screens. Claims and chest
/// openings go through here so both screens stay in sync.
final achievementRoadsProvider =
    AsyncNotifierProvider<AchievementRoadsNotifier, AchievementRoadsData>(
  AchievementRoadsNotifier.new,
);

class AchievementRoadsNotifier extends AsyncNotifier<AchievementRoadsData> {
  final _mutation = OptimisticMutationController<AchievementRoadsData>();
  @override
  Future<AchievementRoadsData> build() => _achievementsService.getRoads();

  /// Reloads without dropping to a loading state (keeps the screen steady).
  Future<void> reload() async {
    final next = await AsyncValue.guard(_achievementsService.getRoads);
    if (next.hasValue || !state.hasValue) state = next;
  }

  Future<AchievementClaimResult> claim(String achievementId) async {
    if (!ClientExperienceService.instance.enabled('achievementsEquipment')) {
      final result = await _achievementsService.claim(achievementId);
      state = AsyncData(state.requireValue
          .claimLocally(achievementId: achievementId)
          .withWallet(result.wallet));
      return result;
    }
    return _mutation.run(
      current: state.requireValue,
      optimistic: (value) => value.claimLocally(achievementId: achievementId),
      request: () => _achievementsService.claim(achievementId),
      reconcile: (predicted, result) => predicted.withWallet(result.wallet),
      publish: (value) => state = AsyncData(value),
      feature: 'achievementsEquipment',
      action: 'claim_achievement',
    );
  }

  Future<AchievementClaimResult> claimAll({String? category}) async {
    if (!ClientExperienceService.instance.enabled('achievementsEquipment')) {
      final result = await _achievementsService.claimAll(category: category);
      state = AsyncData(state.requireValue
          .claimLocally(category: category)
          .withWallet(result.wallet));
      return result;
    }
    return _mutation.run(
      current: state.requireValue,
      optimistic: (value) => value.claimLocally(category: category),
      request: () => _achievementsService.claimAll(category: category),
      reconcile: (predicted, result) => predicted.withWallet(result.wallet),
      publish: (value) => state = AsyncData(value),
      feature: 'achievementsEquipment',
      action: 'claim_achievements',
    );
  }

  Future<StageChestOpenResult> openStageChest(
      String category, String tier) async {
    final result = await _achievementsService.openStageChest(category, tier);
    state = AsyncData(state.requireValue.openChestLocally(result));
    return result;
  }

  /// Other screens (home coins, profile XP, gear) read the character profile.
  void refreshCharacter() => ref.invalidate(characterProfileProvider);
}
