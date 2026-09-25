import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/widgets/item_icon_image.dart';
import '../../rewards/widgets/task_reward_popup.dart';
import '../models/achievement_models.dart';
import 'road_meta.dart';

/// Coins and gems lift out of a claimed row's reward icons and fly into the
/// wallet chips; "+XP" floats up over the row. Mirrors the design's rrFly:
/// each piece pops in at half size, lifts 36 px while swelling to 1.15×, then
/// arcs into the wallet and lands at 0.65×. Completes when the last lands.
Future<void> flyClaimRewards(
  BuildContext context, {
  required Offset coinFrom,
  required Offset gemFrom,
  required Offset xpAt,
  required FxAnchor coinTo,
  required FxAnchor gemTo,
  required int xp,
  Duration delay = Duration.zero,
}) async {
  if (!RewardFx.enabled(context)) return;
  if (xp > 0) {
    RewardFx.floatText(context, xpAt, '+$xp XP', AppColors.orange,
        rise: 52,
        fontSize: 15,
        popScale: 1.1,
        duration: const Duration(milliseconds: 1000),
        delay: delay);
  }
  final flights = <Future<void>>[];
  void send(String asset, Offset from, FxAnchor to, double dx, int delayMs) {
    final target = to.center;
    if (target == null) return;
    flights.add(_rrFly(context,
        asset: asset,
        from: from,
        to: target,
        dx: dx,
        delay: delay + Duration(milliseconds: delayMs)));
  }

  send(AppIcons.homeCoinIcon, coinFrom + const Offset(-20, 0), coinTo, -18, 0);
  send(AppIcons.homeCoinIcon, coinFrom, coinTo, 6, 70);
  send(AppIcons.homeCoinIcon, coinFrom + const Offset(20, 0), coinTo, 22, 140);
  send(AppIcons.homeGemIcon, gemFrom, gemTo, 10, 100);
  send(AppIcons.homeGemIcon, gemFrom + const Offset(14, 0), gemTo, 26, 180);
  await Future.wait(flights);
}

Future<void> _rrFly(
  BuildContext context, {
  required String asset,
  required Offset from,
  required Offset to,
  required double dx,
  required Duration delay,
}) {
  const ease = Cubic(.45, 0, .7, .2);
  final lift = from + Offset(dx, -36);
  return RewardFx.run(
    context,
    duration: const Duration(milliseconds: 700),
    delay: delay,
    builder: (t, origin) {
      final e = ease.transform(t);
      late Offset p;
      late double scale, opacity;
      if (e < .18) {
        final k = e / .18;
        p = Offset.lerp(from, lift, k)!;
        scale = .5 + .65 * k;
        opacity = k;
      } else {
        final k = (e - .18) / .82;
        p = Offset.lerp(lift, to, k)!;
        scale = 1.15 - .5 * k;
        opacity = 1;
      }
      return Positioned(
        left: p.dx - origin.dx - 11,
        top: p.dy - origin.dy - 11,
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
              scale: scale, child: AppIconImage(asset, size: 22)),
        ),
      );
    },
  );
}

/// Shows the stage chest opening with the task reward popup ("You got loot!"),
/// then flies the coin and gem tiles into the wallet.
Future<void> showStageChestPopup(
  BuildContext context, {
  required StageChestOpenResult result,
  required int stageNumber,
  required FxAnchor coinTo,
  required FxAnchor gemTo,
}) async {
  final item = result.item;
  final items = [
    if (item != null)
      TaskRewardItem(
        asset: '',
        label: '×1',
        color: tierColor(item.rarity),
        icon: ItemIconImage(
          itemId: item.id,
          itemName: item.name,
          emojiFallback: item.icon,
          imageUrl: item.inventoryIconUrl,
          size: 50,
        ),
      ),
    if (result.coins > 0)
      TaskRewardItem(
          asset: AppIcons.homeCoinIcon,
          label: '×${result.coins}',
          color: AppColors.orange),
    if (result.gems > 0)
      TaskRewardItem(
          asset: AppIcons.homeGemIcon,
          label: '×${result.gems}',
          color: AppColors.purple),
  ];
  final landed = await showTaskRewardPopup(
    context,
    items: items,
    subtitle: item == null
        ? 'Stage $stageNumber complete · ${result.chestName}'
        : '${item.name} · Stage $stageNumber complete',
    chestAsset: AppIcons.shopChestForKey(result.chestKey),
    lootTitle: false,
    closeHint: false,
  );
  if (!context.mounted || landed.isEmpty) return;
  final flights = <Future<void>>[];
  for (final (i, (from, asset)) in landed.indexed) {
    final to = asset == AppIcons.homeGemIcon ? gemTo.center : coinTo.center;
    if (to == null) continue;
    flights.add(RewardFx.fly(
      context,
      child: AppIconImage(asset, size: 26),
      from: from,
      to: to,
      lift: -40,
      sideways: (i.isOdd ? 1 : -1) * 70,
      endScale: .4,
      spinTurns: 1,
      duration: const Duration(milliseconds: 700),
      delay: Duration(milliseconds: i * 90),
      curve: const Cubic(.6, 0, .9, .7),
    ));
  }
  await Future.wait(flights);
}
