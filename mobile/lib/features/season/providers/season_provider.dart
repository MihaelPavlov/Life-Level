import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/season_models.dart';
import '../services/season_service.dart';

final seasonServiceProvider = Provider<SeasonService>((ref) => SeasonService());

class SeasonNotifier extends AsyncNotifier<SeasonTrack> {
  @override
  Future<SeasonTrack> build() => ref.watch(seasonServiceProvider).getTrack();

  Future<SeasonClaimResult> claim(int tier, String track) async {
    final result = await ref.read(seasonServiceProvider).claimTier(tier, track);
    // Re-fetch authoritative state (tile → received, XP bar may have moved).
    ref.invalidateSelf();
    return result;
  }

  Future<List<SeasonClaimResult>> claimAvailable() async {
    final results = await ref.read(seasonServiceProvider).claimAvailable();
    ref.invalidateSelf();
    return results;
  }

  Future<void> purchaseFounderPass() async {
    final fresh = await ref.read(seasonServiceProvider).purchaseFounderPass();
    state = AsyncValue.data(fresh);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(seasonServiceProvider).getTrack(),
    );
  }
}

final seasonProvider =
    AsyncNotifierProvider<SeasonNotifier, SeasonTrack>(SeasonNotifier.new);
