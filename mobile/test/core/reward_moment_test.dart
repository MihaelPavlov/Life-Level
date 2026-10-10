import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/core/constants/app_colors.dart';
import 'package:life_level/core/services/dungeon_floor_cleared_notifier.dart';
import 'package:life_level/core/widgets/boss_defeated_overlay.dart';
import 'package:life_level/core/widgets/chest_opened_overlay.dart';
import 'package:life_level/core/widgets/dungeon_floor_cleared_overlay.dart';
import 'package:life_level/core/widgets/guild_raid_expired_overlay.dart';
import 'package:life_level/core/widgets/guild_raid_victory_overlay.dart';
import 'package:life_level/core/widgets/inventory_full_overlay.dart';
import 'package:life_level/core/widgets/item_obtained_overlay.dart';
import 'package:life_level/core/widgets/level_up_overlay.dart';
import 'package:life_level/core/widgets/reward_moment/reward_moment.dart';
import 'package:life_level/features/activity/models/activity_models.dart';
import 'package:life_level/features/character/models/level_up_receipt.dart';
import 'package:life_level/features/guild/models/guild_models.dart';
import 'package:life_level/features/items/models/item_models.dart';

/// App with a tap target that fires [show]; returns once it's on screen.
Future<void> _open(WidgetTester tester, void Function(BuildContext) show,
    {Widget? hud, bool banner = false}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              if (hud != null) hud,
              TextButton(
                  onPressed: () => show(context), child: const Text('go')),
            ],
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('go'));
  if (banner) {
    // A banner counts down to hiding itself, so it never "settles".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  group('RewardMoment', () {
    testWidgets('card reveals rewards, Claim closes it and runs onPrimary',
        (tester) async {
      var claimed = false;
      await _open(
        tester,
        (c) => RewardMoment.show(
          c,
          size: RewardMomentSize.card,
          accent: AppColors.orange,
          hero: const RewardEmoji('🎁'),
          label: 'Chest opened',
          title: 'Thornwood Cache',
          rewards: const [RewardLine.xp(250), RewardLine.coins(60)],
          onPrimary: () => claimed = true,
        ),
      );
      expect(RewardMoment.isBlockingMomentShowing, isTrue);
      expect(find.text('CHEST OPENED'), findsOneWidget);
      expect(find.text('Thornwood Cache'), findsOneWidget);
      // Values count up and settle on the real amounts.
      expect(find.text('+250'), findsOneWidget);
      expect(find.text('+60'), findsOneWidget);

      await tester.tap(find.text('Claim'));
      await tester.pumpAndSettle();
      expect(find.text('Thornwood Cache'), findsNothing);
      expect(claimed, isTrue);
      expect(RewardMoment.isBlockingMomentShowing, isFalse);
    });

    testWidgets('claimed rewards fly to a visible HUD target', (tester) async {
      await _open(
        tester,
        (c) => RewardMoment.show(
          c,
          size: RewardMomentSize.card,
          accent: AppColors.orange,
          hero: const RewardEmoji('🎁'),
          label: 'Chest opened',
          title: 'Cache',
          rewards: const [RewardLine.coins(60)],
        ),
        hud: const RewardHudTarget(
          kind: RewardKind.coins,
          child: SizedBox(width: 40, height: 20),
        ),
      );
      expect(RewardHud.rectFor(RewardKind.coins), isNotNull);
      await tester.tap(find.text('Claim'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Coin icons are in the air (drawn on the root overlay).
      expect(find.byType(Image), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('Cache'), findsNothing);
    });

    testWidgets('HUD targets only register while their tickers run',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TickerMode(
          enabled: false,
          child: RewardHudTarget(kind: RewardKind.gems, child: SizedBox()),
        ),
      ));
      expect(RewardHud.rectFor(RewardKind.gems), isNull);
      await tester.pumpWidget(const MaterialApp(
        home: TickerMode(
          enabled: true,
          child: RewardHudTarget(kind: RewardKind.gems, child: SizedBox()),
        ),
      ));
      expect(RewardHud.rectFor(RewardKind.gems), isNotNull);
    });

    testWidgets('takeover closes on a tap anywhere', (tester) async {
      await _open(
        tester,
        (c) => RewardMoment.show(
          c,
          size: RewardMomentSize.takeover,
          accent: AppColors.red,
          hero: const RewardEmoji('🐉'),
          label: 'Boss slain',
          title: 'Frost Wyrm vanquished',
          rewards: const [RewardLine.xp(1200)],
        ),
      );
      expect(find.text('Tap anywhere to continue'), findsOneWidget);
      await tester.tapAt(const Offset(195, 120));
      await tester.pumpAndSettle();
      expect(find.text('Frost Wyrm vanquished'), findsNothing);
    });

    testWidgets('banner hides itself after its duration', (tester) async {
      await _open(
        tester,
        (c) => RewardMoment.show(
          c,
          size: RewardMomentSize.banner,
          accent: AppColors.green,
          hero: const RewardEmoji('⚡'),
          label: 'Floor cleared',
          title: 'Floor 2 of 3 cleared',
          bannerDuration: const Duration(seconds: 2),
        ),
        banner: true,
      );
      expect(RewardMoment.isBlockingMomentShowing, isFalse);
      expect(find.text('Floor 2 of 3 cleared'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Floor 2 of 3 cleared'), findsNothing);
    });

    testWidgets('banner action runs onPrimary', (tester) async {
      var managed = false;
      await _open(
        tester,
        (c) => RewardMoment.show(
          c,
          size: RewardMomentSize.banner,
          tone: RewardMomentTone.warning,
          accent: AppColors.orange,
          hero: const RewardEmoji('👢'),
          label: 'Inventory full',
          title: "Worn Boots didn't fit",
          primaryLabel: 'Manage',
          onPrimary: () => managed = true,
        ),
        banner: true,
      );
      await tester.tap(find.text('Manage'));
      await tester.pumpAndSettle();
      expect(managed, isTrue);
      expect(find.text("Worn Boots didn't fit"), findsNothing);
    });
  });

  group('migrated popups render and close', () {
    Future<void> claimAndClose(WidgetTester tester, String button) async {
      await tester.tap(find.text(button).last);
      await tester.pumpAndSettle();
    }

    testWidgets('floor cleared → banner', (tester) async {
      await _open(
          tester,
          (c) => showDungeonFloorClearedOverlay(
              c,
              const DungeonFloorClearedEvent(
                  dungeonName: 'Sunken Crypt',
                  clearedFloorOrdinal: 2,
                  totalFloors: 3,
                  runCompleted: false,
                  bonusXpAwarded: 0)),
          banner: true);
      expect(find.text('Floor 2 of 3 cleared'), findsOneWidget);
      expect(find.text('Sunken Crypt · Floor 3 is now active'), findsOneWidget);
      await claimAndClose(tester, 'Nice');
    });

    testWidgets('dungeon run complete → takeover', (tester) async {
      await _open(
          tester,
          (c) => showDungeonFloorClearedOverlay(
              c,
              const DungeonFloorClearedEvent(
                  dungeonName: 'Sunken Crypt',
                  clearedFloorOrdinal: 3,
                  totalFloors: 3,
                  runCompleted: true,
                  bonusXpAwarded: 450)));
      expect(RewardMoment.isBlockingMomentShowing, isTrue);
      expect(find.text('DUNGEON CONQUERED'), findsOneWidget);
      expect(find.text('Sunken Crypt'), findsOneWidget);
      expect(find.text('3 of 3 trials cleared'), findsOneWidget);
      expect(find.text('+450'), findsOneWidget);
      await claimAndClose(tester, 'Claim');
      expect(find.text('Sunken Crypt'), findsNothing);
      expect(RewardMoment.isBlockingMomentShowing, isFalse);
    });

    testWidgets('dungeon takeover: a tap mid-reveal skips to the end',
        (tester) async {
      await _open(
          tester,
          (c) => showDungeonFloorClearedOverlay(
              c,
              const DungeonFloorClearedEvent(
                  dungeonName: 'Sunken Crypt',
                  clearedFloorOrdinal: 5,
                  totalFloors: 5,
                  runCompleted: true,
                  bonusXpAwarded: 1200)),
          banner: true); // stop pumping while the ring is still drawing
      await tester.tapAt(const Offset(195, 120));
      await tester.pump();
      expect(find.text('+1,200'), findsOneWidget);
      expect(find.text('5 of 5 trials cleared'), findsOneWidget);
      // Still open: the skip doesn't claim.
      expect(find.text('Claim'), findsOneWidget);
      await claimAndClose(tester, 'Claim');
      expect(find.text('Sunken Crypt'), findsNothing);
    });

    testWidgets('map chest uses the task reward opening', (tester) async {
      await _open(
          tester,
          (c) =>
              showChestOpenedOverlay(c, zoneName: 'Thornwood Cache', xp: 250));
      expect(find.text('You got loot!'), findsWidgets);
      expect(find.text('Thornwood Cache'), findsOneWidget);
      expect(find.text('+250 XP'), findsWidgets);
      await tester.tap(find.text('Tap to close'));
      await tester.pumpAndSettle();
      expect(find.text('You got loot!'), findsNothing);
    });

    testWidgets('boss slain → takeover', (tester) async {
      await _open(
          tester,
          (c) => showBossDefeatedOverlay(
              c,
              const BossDefeatedInfo(
                  bossId: 'b1',
                  name: 'Frost Wyrm',
                  icon: '🐉',
                  rewardXp: 1200,
                  isMini: false)));
      expect(find.text('Frost Wyrm vanquished'), findsOneWidget);
      expect(find.text('Tap anywhere to continue'), findsOneWidget);
      await claimAndClose(tester, 'Claim');
      expect(find.text('Frost Wyrm vanquished'), findsNothing);
    });

    testWidgets('mini-boss slain → card', (tester) async {
      await _open(
          tester,
          (c) => showBossDefeatedOverlay(
              c,
              const BossDefeatedInfo(
                  bossId: 'b2',
                  name: 'Bog Troll',
                  icon: '👹',
                  rewardXp: 300,
                  isMini: true)));
      expect(find.text('Bog Troll is down'), findsOneWidget);
      expect(find.text('Tap anywhere to continue'), findsNothing);
      await claimAndClose(tester, 'Claim');
    });

    testWidgets('guild raid victory → takeover with contribution',
        (tester) async {
      await _open(
          tester,
          (c) => showGuildRaidVictoryOverlay(
              c,
              const GuildRaidVictoryInfo(
                  guildId: 'g',
                  guildRaidId: 'r',
                  bossName: 'Ashen Colossus',
                  bossIcon: '🗿',
                  rewardXp: 800,
                  mvpBonusXp: 200,
                  topContributorUsername: 'Kestrel',
                  topContributorDamage: 6020,
                  yourDamage: 4210,
                  totalDamage: 38500)));
      expect(find.text('Ashen Colossus falls'), findsOneWidget);
      expect(find.text('Kestrel · 6,020'), findsOneWidget);
      expect(find.text('+200'), findsOneWidget);
      await claimAndClose(tester, 'Claim');
    });

    testWidgets('guild raid expired → grey loss card', (tester) async {
      await _open(
          tester,
          (c) => showGuildRaidExpiredOverlay(
              c,
              const GuildRaidExpiredInfo(
                  guildId: 'g',
                  guildRaidId: 'r',
                  bossName: 'Ashen Colossus',
                  bossIcon: '🗿',
                  maxHp: 40000,
                  totalDamage: 31200,
                  remainingHp: 8800)));
      expect(find.text('Ashen Colossus escaped'), findsOneWidget);
      expect(find.text('8,800'), findsOneWidget);
      await claimAndClose(tester, 'Close');
    });

    testWidgets('inventory full → warning banner', (tester) async {
      await _open(
          tester,
          (c) => showInventoryFullOverlay(c,
              const BlockedItemInfo(itemName: 'Worn Boots', itemIcon: '👢'), 8),
          banner: true);
      expect(find.text("Worn Boots didn't fit"), findsOneWidget);
      expect(find.text('Free a slot, or reach Level 10 → 40 slots.'),
          findsOneWidget);
      // Swiping it away dismisses without switching tabs.
      await tester.fling(
          find.text("Worn Boots didn't fit"), const Offset(0, -200), 1500);
      await tester.pumpAndSettle();
      expect(find.text("Worn Boots didn't fit"), findsNothing);
    });

    testWidgets('new item → card in rarity colour, Later closes',
        (tester) async {
      await _open(
          tester,
          (c) => showItemObtainedOverlay(
              c,
              const ItemDto(
                  id: 'i1',
                  name: 'Stormrunner Shoes',
                  description: 'Light shoes stitched with storm silk.',
                  icon: '👟',
                  rarity: 'rare',
                  slotType: 'feet',
                  xpBonusPct: 5,
                  strBonus: 0,
                  endBonus: 2,
                  agiBonus: 3,
                  flxBonus: 0,
                  staBonus: 0,
                  characterItemId: 'ci1',
                  isEquipped: false,
                  category: 'gear')));
      expect(find.text('NEW ITEM · RARE'), findsOneWidget);
      expect(find.text('+3 AGI'), findsOneWidget);
      expect(find.text('Equip now'), findsOneWidget);
      await claimAndClose(tester, 'Later');
      expect(find.text('Stormrunner Shoes'), findsNothing);
    });

    testWidgets('level up → takeover with unlocks', (tester) async {
      await _open(
          tester,
          (c) => showLevelUpScreen(c, 12,
              unlocks: const LevelUpUnlocks(
                  statPointsGained: 1, grantedItems: [], unlockedZones: [])));
      expect(find.text('Level 12'), findsOneWidget);
      expect(find.text('+1 Stat Point'), findsOneWidget);
      await claimAndClose(tester, 'Continue');
      expect(find.text('Level 12'), findsNothing);
    });

    testWidgets('level-up receipt shows real grouped changes', (tester) async {
      const receipt = LevelUpReceipt(
        id: 'r1',
        source: 'Activity',
        previousLevel: 9,
        newLevel: 10,
        baseStatPointsGranted: 1,
        bonusStatPointsGranted: 2,
        powerGained: 20,
        coinsGranted: 50,
        previousInventorySlots: 30,
        newInventorySlots: 40,
        grantedItems: [],
        blockedItems: [],
        grantedTitles: [],
        availableAvatars: [LevelUpAvatarInfo('Star', '🌟', 10)],
        availableRegions: [],
      );
      await _open(tester, (c) => showLevelUpScreen(c, 10, receipt: receipt));
      expect(find.text('+3 Stat Points'), findsOneWidget);
      expect(find.text('1 from levels + 2 bonus'), findsOneWidget);
      expect(find.text('+20 Power'), findsOneWidget);
      expect(find.text('+50 Coins'), findsOneWidget);
      expect(find.text('30 → 40 slots'), findsOneWidget);
      expect(find.text('Star'), findsOneWidget);
      await claimAndClose(tester, 'Continue');
    });
  });
}
