import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/character_service.dart';
import '../models/character_profile.dart';
import '../models/xp_history_entry.dart';
import '../../../core/services/level_up_notifier.dart';
import '../../../core/state/optimistic_mutation.dart';
import '../../../core/services/client_experience_service.dart';

// ── CharacterNotifier ─────────────────────────────────────────────────────────
class CharacterNotifier extends AsyncNotifier<CharacterProfile> {
  final _mutation = OptimisticMutationController<CharacterProfile>();
  @override
  Future<CharacterProfile> build() => CharacterService().getProfile();

  Future<void> refresh() async {
    final oldLevel = state.valueOrNull?.level;
    // Fetch silently — keep previous data visible while refreshing.
    final next = await AsyncValue.guard(() => CharacterService().getProfile());
    state = next;
    final newLevel = next.valueOrNull?.level;
    if (oldLevel != null && newLevel != null && newLevel > oldLevel) {
      LevelUpNotifier.notify(newLevel);
    }
  }

  Future<void> spendStatPoint(String stat) async {
    final current = state.requireValue;
    if (!ClientExperienceService.instance.enabled('stats')) {
      state = AsyncData(await CharacterService()
          .spendStatPoint(stat, current.availableStatPoints));
      return;
    }
    await _mutation.run(
      current: current,
      optimistic: (profile) => profile.spendPointLocally(stat),
      request: () =>
          CharacterService().spendStatPoint(stat, current.availableStatPoints),
      reconcile: (_, authoritative) => authoritative,
      publish: (profile) => state = AsyncData(profile),
      feature: 'stats',
      action: 'spend_stat',
    );
  }

  void adjustWalletLocally({int coins = 0, int talentCrystals = 0}) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.adjustWalletLocally(
        coins: coins, talentCrystals: talentCrystals));
  }
}

final characterProfileProvider =
    AsyncNotifierProvider<CharacterNotifier, CharacterProfile>(
        CharacterNotifier.new);

// ── XP History ────────────────────────────────────────────────────────────────
// autoDispose so it re-fetches each time the sheet opens.
final xpHistoryProvider = FutureProvider.autoDispose<List<XpHistoryEntry>>(
  (_) => CharacterService().getXpHistory(),
);
