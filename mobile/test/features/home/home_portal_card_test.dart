import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/core/services/map_focus_notifier.dart';
import 'package:life_level/core/services/nav_tab_notifier.dart';
import 'package:life_level/features/boss/models/boss_list_item.dart';
import 'package:life_level/features/boss/providers/boss_provider.dart';
import 'package:life_level/features/home/cards/home_portal_card.dart';
import 'package:life_level/features/home/providers/world_progress_provider.dart';
import 'package:life_level/features/map/models/world_map_models.dart';
import 'package:life_level/features/map/models/world_zone_models.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeBossListNotifier extends BossListNotifier {
  _FakeBossListNotifier(this.items);
  final List<BossListItem> items;

  @override
  Future<List<BossListItem>> build() async => items;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

WorldZoneModel _zone({
  required String id,
  required String type,
  String name = 'Test Zone',
  int totalXp = 100,
  int nodeCount = 3,
  int completedNodeCount = 1,
}) =>
    WorldZoneModel(
      id: id,
      name: name,
      description: 'desc',
      icon: '🧭',
      region: 'Whispering Woods',
      tier: 2,
      positionX: 0,
      positionY: 0,
      levelRequirement: 1,
      totalXp: totalXp,
      totalDistanceKm: 3.0,
      isCrossroads: type == 'crossroads',
      isStartZone: false,
      nodeCount: nodeCount,
      completedNodeCount: completedNodeCount,
      type: type,
    );

WorldFullData _world({
  required List<WorldZoneModel> zones,
  required String currentZoneId,
  String? destinationZoneId,
  String? currentEdgeId,
  List<WorldZoneEdgeModel> edges = const [],
  String? currentRegionId,
}) =>
    WorldFullData(
      zones: zones,
      edges: edges,
      userProgress: WorldUserProgress(
        currentZoneId: currentZoneId,
        destinationZoneId: destinationZoneId,
        currentEdgeId: currentEdgeId,
        distanceTraveledOnEdge: 1.0,
        unlockedZoneIds: zones.map((z) => z.id).toList(),
        currentRegionId: currentRegionId,
      ),
      characterLevel: 5,
    );

RegionDetail _region({
  String name = 'Whispering Woods',
  String emoji = '🌲',
  int chapterIndex = 1,
  List<ZoneNode> nodes = const [],
}) =>
    RegionDetail(
      id: 'region-1',
      name: name,
      emoji: emoji,
      lore: 'a cold forest',
      bossName: 'Warden',
      theme: RegionTheme.forest,
      chapterIndex: chapterIndex,
      levelRequirement: 1,
      completedZones: 1,
      totalZones: 5,
      totalXpEarned: 0,
      zonesUntilBoss: 2,
      status: RegionStatus.active,
      bossStatus: RegionBossStatus.locked,
      pins: const [],
      nodes: nodes,
      edges: const [],
      pathChoices: const {},
    );

ZoneNode _zoneNode({
  required String id,
  bool isChest = false,
  bool isDungeon = false,
  int? chestRewardXp,
  int? dungeonFloorsTotal,
  int? dungeonFloorsCompleted,
}) =>
    ZoneNode(
      id: id,
      name: 'node',
      emoji: '🧭',
      description: '',
      tier: 1,
      levelRequirement: 1,
      xpReward: 10,
      distanceKm: 1.0,
      status: ZoneNodeStatus.available,
      isCrossroads: false,
      isBoss: false,
      isChest: isChest,
      isDungeon: isDungeon,
      chestRewardXp: chestRewardXp,
      dungeonFloorsTotal: dungeonFloorsTotal,
      dungeonFloorsCompleted: dungeonFloorsCompleted,
    );

BossListItem _activeBoss() => BossListItem(
      id: 'b1',
      name: 'Forest Warden',
      icon: '👹',
      maxHp: 1000,
      rewardXp: 500,
      timerDays: 7,
      isMini: false,
      region: 'ForestOfEndurance',
      nodeName: 'Warden',
      levelRequirement: 5,
      canFight: true,
      activated: true,
      hpDealt: 200,
      isDefeated: false,
      isExpired: false,
      timerExpiresAt: DateTime.now().toUtc().add(const Duration(days: 3)),
    );

Widget _harness({
  required WorldFullData world,
  RegionDetail? region,
  List<BossListItem> bosses = const [],
}) {
  return ProviderScope(
    overrides: [
      bossListProvider.overrideWith(() => _FakeBossListNotifier(bosses)),
      worldProgressProvider
          .overrideWith((ref) async => world),
      currentRegionDetailProvider
          .overrideWith((ref) async => region),
    ],
    child: const MaterialApp(
      home: Scaffold(body: HomePortalCard()),
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders standard portal on entry zone', (tester) async {
    final zone = _zone(id: 'z1', type: 'entry', name: 'Forest Gate');
    await tester.pumpWidget(_harness(
      world: _world(zones: [zone], currentZoneId: 'z1'),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Forest Gate'), findsOneWidget);
    expect(find.text('Open map →'), findsOneWidget);
  });

  testWidgets('renders boss priority portal when an active boss exists',
      (tester) async {
    final zone = _zone(id: 'z1', type: 'entry', name: 'Forest Gate');
    await tester.pumpWidget(_harness(
      world: _world(zones: [zone], currentZoneId: 'z1'),
      bosses: [_activeBoss()],
    ));
    await tester.pumpAndSettle();
    expect(find.text('Forest Warden'), findsOneWidget);
    expect(find.text('Fight →'), findsOneWidget);
    // The standard "Open map →" must NOT render when boss is priority.
    expect(find.text('Open map →'), findsNothing);
  });

  testWidgets('chest portal shows reward XP from region detail node',
      (tester) async {
    final zone = _zone(id: 'z1', type: 'chest', name: 'Hidden Shrine');
    final region = _region(
      nodes: [_zoneNode(id: 'z1', isChest: true, chestRewardXp: 250)],
    );
    await tester.pumpWidget(_harness(
      world: _world(
        zones: [zone],
        currentZoneId: 'z1',
        currentRegionId: 'region-1',
      ),
      region: region,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hidden Shrine'), findsOneWidget);
    expect(find.text('+250 XP'), findsOneWidget);
    expect(find.text('Open chest →'), findsOneWidget);
  });

  testWidgets('dungeon portal shows floor progress from region detail node',
      (tester) async {
    final zone = _zone(id: 'z1', type: 'dungeon', name: 'Pale Hollow');
    final region = _region(
      nodes: [
        _zoneNode(
          id: 'z1',
          isDungeon: true,
          dungeonFloorsTotal: 3,
          dungeonFloorsCompleted: 1,
        ),
      ],
    );
    await tester.pumpWidget(_harness(
      world: _world(
        zones: [zone],
        currentZoneId: 'z1',
        currentRegionId: 'region-1',
      ),
      region: region,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pale Hollow'), findsOneWidget);
    expect(find.textContaining('FLOOR 2 / 3'), findsOneWidget);
    expect(find.text('Enter dungeon →'), findsOneWidget);
  });

  testWidgets('crossroads portal lists branches from edges', (tester) async {
    final cr = _zone(id: 'x', type: 'crossroads', name: 'Fork');
    final a = _zone(id: 'a', type: 'zone', name: 'Branch A');
    final b = _zone(id: 'b', type: 'zone', name: 'Branch B');
    await tester.pumpWidget(_harness(
      world: _world(
        zones: [cr, a, b],
        currentZoneId: 'x',
        edges: const [
          WorldZoneEdgeModel(
            id: 'e1',
            fromZoneId: 'x',
            toZoneId: 'a',
            distanceKm: 1,
            isBidirectional: false,
          ),
          WorldZoneEdgeModel(
            id: 'e2',
            fromZoneId: 'x',
            toZoneId: 'b',
            distanceKm: 1,
            isBidirectional: false,
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Choose path →'), findsOneWidget);
    expect(find.textContaining('Branch A'), findsOneWidget);
    expect(find.textContaining('Branch B'), findsOneWidget);
  });

  testWidgets('region chip shows name + chapter when region is present',
      (tester) async {
    final zone = _zone(id: 'z1', type: 'entry');
    await tester.pumpWidget(_harness(
      world: _world(
        zones: [zone],
        currentZoneId: 'z1',
        currentRegionId: 'region-1',
      ),
      region: _region(name: 'Crown Peaks', emoji: '⛰', chapterIndex: 2),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Crown Peaks'), findsOneWidget);
    expect(find.textContaining('Ch. 2'), findsOneWidget);
  });

  testWidgets('CTA fires MapFocusNotifier with zone id and switches to map tab',
      (tester) async {
    final zone = _zone(id: 'target-zone', type: 'entry');
    await tester.pumpWidget(_harness(
      world: _world(zones: [zone], currentZoneId: 'target-zone'),
    ));
    await tester.pumpAndSettle();

    // Broadcast stream subscribers are bound to the zone they're registered
    // in. To observe the synchronous static `add()` from inside the tap, set
    // up the listener AND tap inside the same runAsync block (real zone).
    final focusEvents = <String?>[];
    final tabEvents = <String>[];
    await tester.runAsync(() async {
      final focusSub = MapFocusNotifier.stream.listen(focusEvents.add);
      final tabSub = NavTabNotifier.stream.listen(tabEvents.add);
      await tester.tap(find.text('Open map →'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await focusSub.cancel();
      await tabSub.cancel();
    });

    expect(focusEvents, contains('target-zone'));
    expect(tabEvents, contains('map'));
  });
}
