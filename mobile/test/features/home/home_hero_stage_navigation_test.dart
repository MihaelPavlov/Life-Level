import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/services/nav_tab_notifier.dart';
import 'package:life_level/features/activity/models/activity_models.dart';
import 'package:life_level/features/activity/providers/activity_provider.dart';
import 'package:life_level/features/home/cards/home_hero_stage.dart';
import 'package:life_level/features/home/providers/world_progress_provider.dart';
import 'package:life_level/features/gear/widgets/gear_paperdoll.dart';
import 'package:life_level/features/items/models/item_models.dart';
import 'package:life_level/features/items/providers/items_provider.dart';
import 'package:life_level/features/map/models/world_zone_models.dart';
import 'package:life_level/features/streak/models/streak_models.dart';
import 'package:life_level/features/streak/providers/streak_provider.dart';

import '../../helpers/unlocks_overrides.dart';

class _PendingStreak extends StreakNotifier {
  @override
  Future<StreakData> build() => Completer<StreakData>().future;
}

class _EquippedChest extends EquipmentNotifier {
  @override
  Future<CharacterEquipmentResponse> build() async =>
      const CharacterEquipmentResponse(
        slots: [
          EquipmentSlotDto(
            slotType: 'Chest',
            item: ItemDto(
              id: 'hoodie',
              name: 'Tactical Raid Hoodie',
              description: '',
              icon: '',
              rarity: 'Rare',
              slotType: 'Chest',
              xpBonusPct: 0,
              strBonus: 0,
              endBonus: 0,
              agiBonus: 0,
              flxBonus: 0,
              staBonus: 0,
              isEquipped: true,
            ),
          ),
        ],
        totalBonuses: GearBonusesDto(
          xpBonusPct: 0,
          strBonus: 0,
          endBonus: 0,
          agiBonus: 0,
          flxBonus: 0,
          staBonus: 0,
        ),
      );
}

void main() {
  testWidgets('hero profile and gear artwork switch to the expected tabs',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tabs = <String>[];
    final subscription = NavTabNotifier.stream.listen(tabs.add);
    addTearDown(subscription.cancel);
    final world = Completer<WorldFullData>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUnlockedOverride,
          worldProgressProvider.overrideWith((ref) => world.future),
          streakProvider.overrideWith(_PendingStreak.new),
          equipmentProvider.overrideWith(_EquippedChest.new),
          activitySummaryProvider.overrideWith(
            (ref) async => const ActivitySummary(totalSteps: 12345),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(body: HomeHeroStage()),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(GearPaperDoll), findsOneWidget);
    expect(find.text('12,345'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-profile-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-mount-button')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-weapon-button')));
    await tester.pump();

    expect(tabs, ['profile', 'gear', 'gear']);

    await tester.tap(find.byKey(const ValueKey('home-banked-distance-button')));
    await tester.pump();
    expect(find.text('Banked Distance'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home-shields-button')));
    await tester.pump();
    expect(find.text('Streak Shields'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home-power-button')));
    await tester.pump();
    expect(find.text('Power'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home-steps-button')));
    await tester.pump();
    expect(find.text('Steps'), findsOneWidget);
  });
}
