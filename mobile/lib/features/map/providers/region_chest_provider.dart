import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/region_chest_models.dart';
import '../services/region_chest_service.dart';

final regionChestServiceProvider =
    Provider<RegionChestService>((_) => RegionChestService());

final regionChestsProvider =
    AsyncNotifierProvider<RegionChestsNotifier, RegionChestsOverview>(
        RegionChestsNotifier.new);

class RegionChestsNotifier extends AsyncNotifier<RegionChestsOverview> {
  @override
  Future<RegionChestsOverview> build() =>
      ref.read(regionChestServiceProvider).getOverview();

  Future<RegionChestClaimResult> claim(String regionId) async {
    final result = await ref.read(regionChestServiceProvider).claim(regionId);
    final current = state.valueOrNull;
    if (current != null) state = AsyncValue.data(current.apply(result));
    return result;
  }
}
