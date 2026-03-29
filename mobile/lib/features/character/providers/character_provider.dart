import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../character_service.dart';
import '../models/character_profile.dart';
import '../models/xp_history_entry.dart';
import '../../../core/services/level_up_notifier.dart';

// ── CharacterNotifier ─────────────────────────────────────────────────────────
class CharacterNotifier extends AsyncNotifier<CharacterProfile> {
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
    await CharacterService().spendStatPoint(stat);
    await refresh();
  }
}

final characterProfileProvider =
    AsyncNotifierProvider<CharacterNotifier, CharacterProfile>(CharacterNotifier.new);

// ── XP History ────────────────────────────────────────────────────────────────
// autoDispose so it re-fetches each time the sheet opens.
final xpHistoryProvider = FutureProvider.autoDispose<List<XpHistoryEntry>>(
  (_) => CharacterService().getXpHistory(),
);
