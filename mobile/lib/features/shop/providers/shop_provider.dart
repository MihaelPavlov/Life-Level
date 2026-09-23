import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_models.dart';
import '../services/shop_service.dart';

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
  Future<ShopPurchaseResult> buyItem(String id) async {
    final result = await ref.read(shopServiceProvider).buyItem(id);
    state = AsyncData(result.shop);
    return result;
  }

  Future<ShopPurchaseResult> buyChest(String tier) async {
    final result = await ref.read(shopServiceProvider).buyChest(tier);
    state = AsyncData(result.shop);
    return result;
  }
}
