import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/motion/reward_fx.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/item_icon_image.dart';
import '../../core/widgets/item_obtained_overlay.dart';
import '../character/providers/character_provider.dart';
import '../items/models/item_models.dart';
import '../items/providers/items_provider.dart';
import '../talents/providers/talents_provider.dart';
import '../talents/talents_screen.dart';
import 'models/shop_models.dart';
import 'providers/shop_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool busy = false;
  Timer? timer;

  /// Item id of the offer just bought — its tile plays the SOLD stamp.
  final _soldId = ValueNotifier<String?>(null);
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _soldId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(shopProvider);
    return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: ref.read(shopProvider.notifier).reload,
          child: value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListView(children: [
              _Error(
                  message: e.toString(),
                  retry: ref.read(shopProvider.notifier).reload)
            ]),
            data: (shop) => ListView(padding: EdgeInsets.zero, children: [
              _Header(shop.wallet),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _TalentBanner(
                      onTap: () => Navigator.push(context,
                          AppRoute(builder: (_) => const TalentsScreen())))),
              _Daily(
                  shop: shop,
                  busy: busy,
                  refresh: _refresh,
                  soldId: _soldId,
                  select: (o) => _offer(shop, o)),
              _Chests(shop: shop, busy: busy, select: (c) => _chest(shop, c)),
              const _ComingSoon(
                  icon: '💎',
                  title: 'Gem Packs',
                  text: 'More ways to earn Gems are coming soon.'),
              const _ComingSoon(
                  icon: '🪙',
                  title: 'Coin Packs',
                  text: 'Store purchases are coming soon.'),
              const SizedBox(height: 32),
            ]),
          ),
        ));
  }

  Future<void> _refresh() async {
    if (busy) return;
    setState(() => busy = true);
    await ref.read(shopProvider.notifier).refreshOffers();
    if (mounted) {
      final s = ref.read(shopProvider);
      if (s.hasError) AppToast.error(context, s.error.toString());
      setState(() => busy = false);
    }
  }

  Future<void> _offer(ShopData shop, ShopOffer offer) async {
    if (!offer.canPurchase || busy) return;
    final yes = await showAppBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _BuySheet(
            item: offer.item,
            title: offer.item.name,
            price: offer.price,
            currency: offer.currency,
            shop: shop));
    if (yes == true) {
      await _purchase(
          () => ref.read(shopProvider.notifier).buyItem(offer.item.id),
          soldItemId: offer.item.id);
    }
  }

  Future<void> _chest(ShopData shop, ShopChest chest) async {
    if (!chest.canPurchase || busy) return;
    final yes = await showAppBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _BuySheet(
            title: chest.displayName,
            price: chest.price,
            currency: chest.currency,
            shop: shop,
            rarity: chest.rarity,
            detail: 'Contains one random unowned ${chest.rarity} gear item.'));
    if (yes == true) {
      await _purchase(
          () => ref.read(shopProvider.notifier).buyChest(chest.key));
    }
  }

  Future<void> _purchase(Future<ShopPurchaseResult> Function() action,
      {String? soldItemId}) async {
    if (!mounted) return;
    setState(() => busy = true);
    try {
      final result = await action();
      ref.invalidate(inventoryProvider);
      ref.invalidate(equipmentProvider);
      ref.invalidate(characterProfileProvider);
      ref.invalidate(talentsProvider);
      if (soldItemId != null && mounted && RewardFx.enabled(context)) {
        // Let the SOLD stamp land before the reward overlay covers it.
        _soldId.value = soldItemId;
        await Future.delayed(const Duration(milliseconds: 900));
      }
      if (mounted) showItemObtainedOverlay(context, result.grantedItem);
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
      await ref.read(shopProvider.notifier).reload();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _Header extends StatelessWidget {
  final ShopWallet wallet;
  const _Header(this.wallet);
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
        height: top + 142,
        child: Stack(children: [
          Positioned.fill(
              child: Image.asset(AppIcons.shopHeaderBg, fit: BoxFit.cover)),
          Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                Colors.black.withValues(alpha: .12),
                Colors.black.withValues(alpha: .4),
                AppColors.background
              ])))),
          Positioned(
              left: 12,
              top: top + 6,
              child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                      backgroundColor: const Color(0xCC0B1420)))),
          const Positioned(
              left: 18,
              bottom: 18,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shop',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900)),
                    Text('GEAR UP. KEEP MOVING.',
                        style: TextStyle(
                            color: Color(0xFF8DBDFF),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6))
                  ])),
          Positioned(
              right: 16,
              top: top + 6,
              child: Row(children: [
                _Currency(AppIcons.homeCoinIcon, wallet.coins),
                const SizedBox(width: 8),
                _Currency(AppIcons.homeGemIcon, wallet.gems)
              ])),
        ]));
  }
}

class _Currency extends StatelessWidget {
  final String asset;
  final int value;
  const _Currency(this.asset, this.value);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xEE101824),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF354359))),
      child: Row(children: [
        Image.asset(asset, width: 20),
        const SizedBox(width: 6),
        FlapText(_num(value),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900))
      ]));
}

class _TalentBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _TalentBanner({required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.purple.withValues(alpha: .55)),
              gradient: const LinearGradient(
                  colors: [Color(0xFF281748), Color(0xFF151B2A)])),
          child: Row(children: [
            Image.asset(AppIcons.talentCrystalIcon, width: 50),
            const SizedBox(width: 12),
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Talent Draw',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  SizedBox(height: 3),
                  Text('Unlock and level up permanent talents.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11))
                ])),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFC8A3FF), size: 30)
          ])));
}

class _Daily extends StatelessWidget {
  final ShopData shop;
  final bool busy;
  final VoidCallback refresh;
  final ValueListenable<String?> soldId;
  final ValueChanged<ShopOffer> select;
  const _Daily(
      {required this.shop,
      required this.busy,
      required this.refresh,
      required this.soldId,
      required this.select});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(children: [
        _Title(
            title: 'Daily Shop',
            subtitle: _countdown(shop.resetAtUtc),
            trailing: TextButton.icon(
                onPressed: shop.refresh.canRefresh && !busy ? refresh : null,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: Text(shop.refresh.refreshed
                    ? 'Used today'
                    : '${shop.refresh.costCoins} Coins'))),
        const SizedBox(height: 12),
        GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shop.dailyOffers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10),
            itemBuilder: (_, i) => _SoldStamp(
                  itemId: shop.dailyOffers[i].item.id,
                  soldId: soldId,
                  child: _Offer(shop.dailyOffers[i], busy,
                      () => select(shop.dailyOffers[i])),
                )),
        if (!shop.refresh.canRefresh && shop.refresh.unavailableReason != null)
          Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(shop.refresh.unavailableReason!,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10))),
      ]));
}

class _Title extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const _Title({required this.title, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18)),
          if (subtitle != null)
            Text(subtitle!,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 10))
        ])),
        if (trailing != null) trailing!
      ]);
}

/// Slams a red SOLD stamp onto its child when [soldId] matches [itemId]:
/// the stamp drops from 3× with a tilt, the tile dips, dust puffs out, and
/// the stamp stays on the (now owned) tile.
class _SoldStamp extends StatefulWidget {
  final String itemId;
  final ValueListenable<String?> soldId;
  final Widget child;
  const _SoldStamp(
      {required this.itemId, required this.soldId, required this.child});

  @override
  State<_SoldStamp> createState() => _SoldStampState();
}

class _SoldStampState extends State<_SoldStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520))
    ..addListener(() => setState(() {}));
  final _key = GlobalKey();
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    widget.soldId.addListener(_check);
  }

  void _check() {
    if (widget.soldId.value != widget.itemId) return;
    _c.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      setState(() => _landed = true);
      final r = RewardFx.rectOf(_key);
      if (r != null) {
        RewardFx.burst(
            context, r.center + const Offset(0, 10), const Color(0x99BEC8D2),
            count: 16,
            distance: 80,
            size: 7,
            duration: const Duration(milliseconds: 700));
      }
    });
  }

  @override
  void dispose() {
    widget.soldId.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c.value == 0) return widget.child;
    final t = (_c.value / .6).clamp(0.0, 1.0);
    final scale =
        t < .75 ? 3 - 2.08 * (t / .75) : .92 + .08 * ((t - .75) / .25);
    final dip = _landed && _c.value < .9
        ? math.sin(((_c.value - .45) / .45).clamp(0.0, 1.0) * math.pi) * 3
        : 0.0;
    return Stack(
      key: _key,
      alignment: Alignment.center,
      children: [
        Transform.translate(offset: Offset(0, dip), child: widget.child),
        IgnorePointer(
          child: Opacity(
            opacity: (t * 1.4).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: -14 * math.pi / 180,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x73040810),
                    border: Border.all(color: AppColors.red, width: 3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SOLD',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Offer extends StatelessWidget {
  final ShopOffer offer;
  final bool busy;
  final VoidCallback tap;
  const _Offer(this.offer, this.busy, this.tap);
  @override
  Widget build(BuildContext context) {
    final color = rarityColor(offer.item.rarity);
    return Opacity(
        opacity: offer.canPurchase ? 1 : .62,
        child: Material(
            color: const Color(0xFF161E2A),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
                onTap: offer.canPurchase && !busy ? tap : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: color.withValues(alpha: .55))),
                    child: Column(children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(offer.item.rarity.toUpperCase(),
                              style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1))),
                      Expanded(
                          child: ItemIconImage(
                              itemId: offer.item.id,
                              itemName: offer.item.name,
                              emojiFallback: offer.item.icon,
                              imageUrl: offer.item.inventoryIconUrl,
                              size: 82,
                              emojiSize: 44)),
                      Text(offer.item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _Price(offer.currency, offer.price,
                          offer.canPurchase ? null : offer.unavailableReason),
                    ])))));
  }
}

class _Price extends StatelessWidget {
  final String currency;
  final int price;
  final String? label;
  const _Price(this.currency, this.price, this.label);
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF243047),
          borderRadius: BorderRadius.circular(9)),
      child: label != null
          ? Text(label!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(
                  currency == 'Coins'
                      ? AppIcons.homeCoinIcon
                      : AppIcons.homeGemIcon,
                  width: 17),
              const SizedBox(width: 5),
              Text(_num(price),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900))
            ]));
}

class _Chests extends StatelessWidget {
  final ShopData shop;
  final bool busy;
  final ValueChanged<ShopChest> select;
  const _Chests({required this.shop, required this.busy, required this.select});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
      child: Column(children: [
        const _Title(title: 'Chest Vault', subtitle: 'Guaranteed unowned gear'),
        const SizedBox(height: 12),
        ...shop.chests.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Chest(c, busy, () => select(c))))
      ]));
}

class _Chest extends StatelessWidget {
  final ShopChest chest;
  final bool busy;
  final VoidCallback tap;
  const _Chest(this.chest, this.busy, this.tap);
  @override
  Widget build(BuildContext context) {
    final color = rarityColor(chest.rarity);
    return Opacity(
      opacity: chest.canPurchase ? 1 : .62,
      child: Material(
        color: const Color(0xFF161E2A),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: chest.canPurchase && !busy ? tap : null,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: color.withValues(alpha: .5))),
            child: Row(children: [
              Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        color.withValues(alpha: .28),
                        color.withValues(alpha: .08),
                      ]),
                      borderRadius: BorderRadius.circular(13)),
                  child: _ChestArt(rarity: chest.rarity, emojiSize: 31)),
              const SizedBox(width: 11),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(chest.displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                        '${chest.rarity} · ${chest.remainingItemCount} remaining',
                        style: TextStyle(
                            color: color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700)),
                  ])),
              SizedBox(
                  width: 102,
                  child: _Price(chest.currency, chest.price,
                      chest.canPurchase ? null : chest.unavailableReason)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Chest Vault art for a rarity, falling back to the gift emoji.
class _ChestArt extends StatelessWidget {
  final String rarity;
  final double emojiSize;
  const _ChestArt({required this.rarity, required this.emojiSize});
  @override
  Widget build(BuildContext context) {
    final fallback =
        Center(child: Text('🎁', style: TextStyle(fontSize: emojiSize)));
    final art = AppIcons.shopChestFor(rarity);
    if (art == null) return fallback;
    return Image.asset(art,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => fallback);
  }
}

class _ComingSoon extends StatelessWidget {
  final String icon, title, text;
  const _ComingSoon(
      {required this.icon, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: const Color(0xFF141B25),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF2B3645))),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 29)),
            const SizedBox(width: 11),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  Text(text,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 9.5))
                ])),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFF252D39),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('COMING SOON',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900)))
          ])));
}

class _BuySheet extends StatelessWidget {
  final ItemDto? item;
  final String title, currency;
  final int price;
  final ShopData shop;
  final String? rarity, detail;
  const _BuySheet(
      {this.item,
      required this.title,
      required this.price,
      required this.currency,
      required this.shop,
      this.rarity,
      this.detail});
  @override
  Widget build(BuildContext context) {
    final balance = currency == 'Coins' ? shop.wallet.coins : shop.wallet.gems;
    return SafeArea(
        child: Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
            decoration: const BoxDecoration(
                color: Color(0xFF171F2B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFF465164),
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 17),
              if (item != null)
                ItemIconImage(
                    itemId: item!.id,
                    itemName: item!.name,
                    emojiFallback: item!.icon,
                    imageUrl: item!.inventoryIconUrl,
                    size: 88,
                    emojiSize: 48)
              else if (rarity != null)
                SizedBox(
                    width: 120,
                    height: 120,
                    child: _ChestArt(rarity: rarity!, emojiSize: 66))
              else
                const Text('🎁', style: TextStyle(fontSize: 66)),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(item?.description ?? detail ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35)),
              if (item != null)
                Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: _stats(item!)
                            .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF253144),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(s,
                                    style: const TextStyle(
                                        color: Color(0xFF92BFFF),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10))))
                            .toList())),
              const SizedBox(height: 17),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                    'Inventory ${shop.inventoryCount}/${shop.maxInventorySlots}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10.5)),
                Text('Balance ${_num(balance)} $currency',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700))
              ]),
              const SizedBox(height: 12),
              SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13))),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Buy for ',
                                style: TextStyle(fontWeight: FontWeight.w900)),
                            Image.asset(
                                currency == 'Coins'
                                    ? AppIcons.homeCoinIcon
                                    : AppIcons.homeGemIcon,
                                width: 20),
                            const SizedBox(width: 5),
                            Text(_num(price),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900))
                          ]))),
            ])));
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _Error({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(28, 220, 28, 0),
      child: Column(children: [
        const Icon(Icons.storefront_outlined,
            color: AppColors.textMuted, size: 52),
        const SizedBox(height: 13),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 15),
        FilledButton(onPressed: retry, child: const Text('Try again'))
      ]));
}

List<String> _stats(ItemDto i) => [
      if (i.xpBonusPct > 0) '+${i.xpBonusPct}% XP',
      if (i.strBonus > 0) '+${i.strBonus} STR',
      if (i.endBonus > 0) '+${i.endBonus} END',
      if (i.agiBonus > 0) '+${i.agiBonus} AGI',
      if (i.flxBonus > 0) '+${i.flxBonus} FLX',
      if (i.staBonus > 0) '+${i.staBonus} STA'
    ];
String _num(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
String _countdown(DateTime reset) {
  final d = reset.difference(DateTime.now().toUtc());
  return d.isNegative
      ? 'Refreshes shortly'
      : 'Refreshes in ${d.inHours}h ${d.inMinutes.remainder(60)}m';
}
