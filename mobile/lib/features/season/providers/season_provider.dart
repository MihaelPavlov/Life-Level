import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/optimistic_mutation.dart';
import '../../../core/services/client_experience_service.dart';
import '../../../core/api/api_client.dart';
import '../models/season_models.dart';
import '../services/season_service.dart';

final seasonServiceProvider = Provider<SeasonService>((ref) => SeasonService());

class SeasonNotifier extends AsyncNotifier<SeasonTrack> {
  final _mutation = OptimisticMutationController<SeasonTrack>();
  @override
  Future<SeasonTrack> build() => ref.watch(seasonServiceProvider).getTrack();

  Future<SeasonClaimResult> claim(int tier, String track) async {
    final service = ref.read(seasonServiceProvider);
    final operationId = ApiClient.newOperationId();
    if (!ClientExperienceService.instance.enabled('streakSeason')) {
      final result =
          await service.claimTier(tier, track, operationId: operationId);
      state = AsyncData(
          state.requireValue.markClaimsLocally(tier: tier, track: track));
      unawaited(_reconcile(service));
      return result;
    }
    final result = await _mutation.run(
      current: state.requireValue,
      optimistic: (value) => value.markClaimsLocally(tier: tier, track: track),
      request: () => service.claimTier(tier, track, operationId: operationId),
      reconcile: (predicted, _) => predicted,
      publish: (value) => state = AsyncData(value),
      feature: 'streakSeason',
      action: 'claim_season_tier',
    );
    unawaited(_reconcile(service));
    return result;
  }

  Future<List<SeasonClaimResult>> claimAvailable() async {
    final service = ref.read(seasonServiceProvider);
    final operationId = ApiClient.newOperationId();
    if (!ClientExperienceService.instance.enabled('streakSeason')) {
      final results = await service.claimAvailable(operationId: operationId);
      state = AsyncData(state.requireValue.markClaimsLocally());
      unawaited(_reconcile(service));
      return results;
    }
    final results = await _mutation.run(
      current: state.requireValue,
      optimistic: (value) => value.markClaimsLocally(),
      request: () => service.claimAvailable(operationId: operationId),
      reconcile: (predicted, _) => predicted,
      publish: (value) => state = AsyncData(value),
      feature: 'streakSeason',
      action: 'claim_season_available',
    );
    unawaited(_reconcile(service));
    return results;
  }

  Future<void> _reconcile(SeasonService service) async {
    try {
      state = AsyncData(await service.getTrack());
    } catch (_) {
      // Keep the confirmed local state; the next foreground refresh retries.
    }
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
