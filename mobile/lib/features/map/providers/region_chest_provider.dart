import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/region_chest_models.dart';
import '../services/region_chest_service.dart';
import '../../../core/state/optimistic_mutation.dart';
import '../../../core/services/client_experience_service.dart';

final regionChestServiceProvider =
    Provider<RegionChestService>((_) => RegionChestService());

final regionChestsProvider =
    AsyncNotifierProvider<RegionChestsNotifier, RegionChestsOverview>(
        RegionChestsNotifier.new);

class RegionChestsNotifier extends AsyncNotifier<RegionChestsOverview> {
  final _mutation = OptimisticMutationController<RegionChestsOverview>();
  @override
  Future<RegionChestsOverview> build() =>
      ref.read(regionChestServiceProvider).getOverview();

  Future<RegionChestClaimResult> claim(String regionId) async {
    if (!ClientExperienceService.instance.enabled('map')) {
      final result = await ref.read(regionChestServiceProvider).claim(regionId);
      state = AsyncData(state.requireValue.apply(result));
      return result;
    }
    return _mutation.run(
      current: state.requireValue,
      optimistic: (value) =>
          value.claimLocally(regionId, DateTime.now().toUtc()),
      request: () => ref.read(regionChestServiceProvider).claim(regionId),
      reconcile: (predicted, result) => predicted.apply(result),
      publish: (value) => state = AsyncData(value),
      feature: 'map',
      action: 'claim_region_chest',
    );
  }
}
