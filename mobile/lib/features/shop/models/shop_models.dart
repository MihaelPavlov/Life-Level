import '../../items/models/item_models.dart';

class ShopWallet {
  final int coins;
  final int gems;
  const ShopWallet(this.coins, this.gems);
  factory ShopWallet.fromJson(Map<String, dynamic> json) => ShopWallet(
      (json['coins'] as num?)?.toInt() ?? 0,
      (json['gems'] as num?)?.toInt() ?? 0);
}

class ShopRefresh {
  final int costCoins;
  final bool canRefresh;
  final bool refreshed;
  final String? unavailableReason;
  const ShopRefresh(
      this.costCoins, this.canRefresh, this.refreshed, this.unavailableReason);
  factory ShopRefresh.fromJson(Map<String, dynamic> json) => ShopRefresh(
      json['costCoins'] as int? ?? 500,
      json['canRefresh'] as bool? ?? false,
      json['refreshed'] as bool? ?? false,
      json['unavailableReason'] as String?);
}

class ShopOffer {
  final ItemDto item;
  final String currency;
  final int price;
  final bool owned;
  final bool canPurchase;
  final String? unavailableReason;
  const ShopOffer(
      {required this.item,
      required this.currency,
      required this.price,
      required this.owned,
      required this.canPurchase,
      this.unavailableReason});
  factory ShopOffer.fromJson(Map<String, dynamic> json) => ShopOffer(
      item: ItemDto.fromJson(json['item'] as Map<String, dynamic>),
      currency: json['currency'] as String,
      price: json['price'] as int,
      owned: json['owned'] as bool? ?? false,
      canPurchase: json['canPurchase'] as bool? ?? false,
      unavailableReason: json['unavailableReason'] as String?);
}

class ShopChest {
  final String key;
  final String displayName;
  final String rarity;
  final String currency;
  final int price;
  final int remainingItemCount;
  final bool canPurchase;
  final String? unavailableReason;
  const ShopChest(
      {required this.key,
      required this.displayName,
      required this.rarity,
      required this.currency,
      required this.price,
      required this.remainingItemCount,
      required this.canPurchase,
      this.unavailableReason});
  factory ShopChest.fromJson(Map<String, dynamic> json) => ShopChest(
      key: json['key'] as String,
      displayName: json['displayName'] as String,
      rarity: json['rarity'] as String,
      currency: json['currency'] as String,
      price: json['price'] as int,
      remainingItemCount: json['remainingItemCount'] as int? ?? 0,
      canPurchase: json['canPurchase'] as bool? ?? false,
      unavailableReason: json['unavailableReason'] as String?);
}

class ShopData {
  final ShopWallet wallet;
  final DateTime resetAtUtc;
  final ShopRefresh refresh;
  final List<ShopOffer> dailyOffers;
  final List<ShopChest> chests;
  final int inventoryCount;
  final int maxInventorySlots;
  const ShopData(
      {required this.wallet,
      required this.resetAtUtc,
      required this.refresh,
      required this.dailyOffers,
      required this.chests,
      required this.inventoryCount,
      required this.maxInventorySlots});
  factory ShopData.fromJson(Map<String, dynamic> json) => ShopData(
      wallet: ShopWallet.fromJson(json['wallet'] as Map<String, dynamic>),
      resetAtUtc: DateTime.parse(json['resetAtUtc'] as String).toUtc(),
      refresh: ShopRefresh.fromJson(json['refresh'] as Map<String, dynamic>),
      dailyOffers: (json['dailyOffers'] as List<dynamic>)
          .map((e) => ShopOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
      chests: (json['chests'] as List<dynamic>)
          .map((e) => ShopChest.fromJson(e as Map<String, dynamic>))
          .toList(),
      inventoryCount: json['inventoryCount'] as int? ?? 0,
      maxInventorySlots: json['maxInventorySlots'] as int? ?? 0);
}

class ShopPurchaseResult {
  final ShopData shop;
  final ItemDto grantedItem;
  const ShopPurchaseResult(this.shop, this.grantedItem);
  factory ShopPurchaseResult.fromJson(Map<String, dynamic> json) =>
      ShopPurchaseResult(
          ShopData.fromJson(json['shop'] as Map<String, dynamic>),
          ItemDto.fromJson(json['grantedItem'] as Map<String, dynamic>));
}
