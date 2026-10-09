import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_models.dart';
import '../services/shop_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/client_experience_service.dart';

final shopServiceProvider = Provider((_) => ShopService());
final shopProvider =
    AsyncNotifierProvider<ShopNotifier, ShopData>(ShopNotifier.new);

class ShopNotifier extends AsyncNotifier<ShopData> {
  @override
  Future<ShopData> build() => ref.read(shopServiceProvider).getShop();
  Future<void> reload() async =>
      state = await AsyncValue.guard(ref.read(shopServiceProvider).getShop);
  Future<void> refreshOffers() async =>
      state = await AsyncValue.guard(ref.read(shopServiceProvider).refresh);
  Future<ShopPurchaseResult> buyItem(String id, {String? operationId}) async {
    final started = DateTime.now();
    final current = state.requireValue;
    final offer = current.dailyOffers.firstWhere((item) => item.item.id == id);
    final enabled = ClientExperienceService.instance.enabled('shop');
    if (enabled) {
      state = AsyncData(current.purchaseItemLocally(offer));
      ClientExperienceService.instance.record(
          name: 'optimistic_applied', feature: 'shop', outcome: 'buy_item');
    }
    try {
      final result = await ref
          .read(shopServiceProvider)
          .buyItem(id, operationId: operationId ?? ApiClient.newOperationId());
      state = AsyncData(result.shop);
      ClientExperienceService.instance.record(
          name: 'mutation_confirmed',
          feature: 'shop',
          outcome: 'buy_item',
          durationMs: DateTime.now().difference(started).inMilliseconds,
          operationId: operationId);
      return result;
    } catch (_) {
      if (enabled) state = AsyncData(current);
      ClientExperienceService.instance.record(
          name: 'mutation_rolled_back',
          feature: 'shop',
          outcome: 'buy_item',
          durationMs: DateTime.now().difference(started).inMilliseconds,
          operationId: operationId);
      rethrow;
    }
  }

  Future<ShopPurchaseResult> buyChest(String tier,
      {String? operationId}) async {
    final started = DateTime.now();
    final current = state.requireValue;
    final chest = current.chests.firstWhere((item) => item.key == tier);
    final enabled = ClientExperienceService.instance.enabled('shop');
    if (enabled) {
      state = AsyncData(current.purchaseChestLocally(chest));
      ClientExperienceService.instance.record(
          name: 'optimistic_applied', feature: 'shop', outcome: 'buy_chest');
    }
    try {
      final result = await ref.read(shopServiceProvider).buyChest(tier,
          operationId: operationId ?? ApiClient.newOperationId());
      state = AsyncData(result.shop);
      ClientExperienceService.instance.record(
          name: 'mutation_confirmed',
          feature: 'shop',
          outcome: 'buy_chest',
          durationMs: DateTime.now().difference(started).inMilliseconds,
          operationId: operationId);
      return result;
    } catch (_) {
      if (enabled) state = AsyncData(current);
      ClientExperienceService.instance.record(
          name: 'mutation_rolled_back',
          feature: 'shop',
          outcome: 'buy_chest',
          durationMs: DateTime.now().difference(started).inMilliseconds,
          operationId: operationId);
      rethrow;
    }
  }
}
