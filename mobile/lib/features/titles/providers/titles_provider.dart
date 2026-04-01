import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/titles_service.dart';
import '../models/title_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final titlesServiceProvider =
    Provider<TitlesService>((ref) => TitlesService());

// ── TitlesNotifier ─────────────────────────────────────────────────────────────
class TitlesNotifier extends AsyncNotifier<TitlesAndRanksResponse> {
  @override
  Future<TitlesAndRanksResponse> build() =>
      ref.watch(titlesServiceProvider).getTitlesAndRanks();

  Future<void> equipTitle(String titleId) async {
    // Save current state for rollback on error.
    final previous = state;

    // Optimistic update: mark tapped title as equipped, clear others.
    final current = state.valueOrNull;
    if (current != null) {
      TitleDto? tappedTitle;

      final updatedEarned = current.earnedTitles.map((t) {
        final equipped = t.id == titleId;
        if (equipped) tappedTitle = t.copyWith(isEquipped: true);
        return t.copyWith(isEquipped: equipped);
      }).toList();

      final updatedLocked = current.lockedTitles.map((t) {
        return t.copyWith(isEquipped: false);
      }).toList();

      state = AsyncValue.data(current.copyWith(
        activeTitleEmoji: tappedTitle?.emoji ?? current.activeTitleEmoji,
        activeTitleName: tappedTitle?.name ?? current.activeTitleName,
        earnedTitles: updatedEarned,
        lockedTitles: updatedLocked,
      ));
    }

    try {
      await ref.read(titlesServiceProvider).equipTitle(titleId);
      // Re-fetch authoritative state from server.
      ref.invalidateSelf();
    } catch (e) {
      // Restore previous state on error.
      state = previous;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(titlesServiceProvider).getTitlesAndRanks(),
    );
  }
}

final titlesProvider =
    AsyncNotifierProvider<TitlesNotifier, TitlesAndRanksResponse>(
  TitlesNotifier.new,
);
