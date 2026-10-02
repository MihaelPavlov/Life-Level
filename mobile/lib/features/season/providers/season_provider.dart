import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/season_models.dart';
import '../services/season_service.dart';

final seasonServiceProvider = Provider<SeasonService>((ref) => SeasonService());

class SeasonNotifier extends AsyncNotifier<SeasonTrack> {
  @override
  Future<SeasonTrack> build() => ref.watch(seasonServiceProvider).getTrack();

  Future<SeasonClaimResult> claim(int tier, String track) async {
    final service = ref.read(seasonServiceProvider);
    final result = await service.claimTier(tier, track);
    // Keep the existing sliver mounted while fetching authoritative state.
    // Invalidating here briefly replaced the track with a loading spinner
    // during reward animations, which could corrupt the sliver child order.
    final fresh = await service.getTrack();
    state = AsyncValue.data(fresh);
    return result;
  }

  Future<List<SeasonClaimResult>> claimAvailable() async {
    final service = ref.read(seasonServiceProvider);
    final results = await service.claimAvailable();
    final fresh = await service.getTrack();
    state = AsyncValue.data(fresh);
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
