import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('Choose on map →'), findsOneWidget);
    expect(find.textContaining('Branch A'), findsOneWidget);
    expect(find.textContaining('Branch B'), findsOneWidget);
    // The misleading "Possible branches: N" bar from the old layout is gone.
    expect(find.text('Possible branches'), findsNothing);
  });

  testWidgets(
      'crossroads portal excludes the previous zone (bidirectional incoming)',
      (tester) async {
    final cr = _zone(id: 'x', type: 'crossroads', name: 'Fork');
    final prev = _zone(id: 'prev', type: 'dungeon', name: 'Sunken Ruins');
    final a = _zone(id: 'a', type: 'zone', name: 'Branch A');
    final region = _region(nodes: [
      ZoneNode(
        id: 'a',
        name: 'Branch A',
        emoji: '',
        description: '',
        tier: 1,
        levelRequirement: 1,
        xpReward: 0,
        distanceKm: 1,
        status: ZoneNodeStatus.available,
        isCrossroads: false,
        isBoss: false,
        isChest: false,
        isDungeon: false,
        // Authoritative branch marker: this node IS a branch of crossroads x.
        branchOf: 'x',
      ),
    ]);
    await tester.pumpWidget(_harness(
      world: _world(
        zones: [cr, prev, a],
        currentZoneId: 'x',
        currentRegionId: 'region-1',
        edges: const [
          // The user got here via this bidirectional edge from Sunken Ruins.
          WorldZoneEdgeModel(
            id: 'inbound',
            fromZoneId: 'prev',
            toZoneId: 'x',
            distanceKm: 2,
            isBidirectional: true,
          ),
          // Real forward branch.
          WorldZoneEdgeModel(
            id: 'forward',
            fromZoneId: 'x',
            toZoneId: 'a',
            distanceKm: 1,
            isBidirectional: false,
          ),
        ],
      ),
      region: region,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Branch A'), findsOneWidget);
    expect(find.textContaining('Sunken Ruins'), findsNothing);
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

  testWidgets(
      'next-zone hint fires when dungeon run is fully completed',
      (tester) async {
    final dungeonZone =
        _zone(id: 'd', type: 'dungeon', name: 'Pale Hollow');
    final next =
        _zone(id: 'next', type: 'standard', name: 'Crown Path', totalXp: 100);
    final region = _region(
      nodes: [
        // Region detail reports the dungeon as completed — primary signal
        // when DungeonState hasn't loaded yet.
        ZoneNode(
          id: 'd',
          name: 'Pale Hollow',
          emoji: '🗿',
          description: '',
          tier: 1,
          levelRequirement: 1,
          xpReward: 0,
          distanceKm: 1,
          status: ZoneNodeStatus.completed,
          isCrossroads: false,
          isBoss: false,
          isChest: false,
          isDungeon: true,
          dungeonStatus: DungeonRunStatus.completed,
          dungeonFloorsTotal: 3,
          dungeonFloorsCompleted: 3,
        ),
      ],
    );
    await tester.pumpWidget(_harness(
      world: _world(
        zones: [dungeonZone, next],
        currentZoneId: 'd',
        currentRegionId: 'region-1',
        edges: const [
          WorldZoneEdgeModel(
            id: 'e1',
            fromZoneId: 'd',
            toZoneId: 'next',
            distanceKm: 1.5,
            isBidirectional: true,
          ),
        ],
      ),
      region: region,
    ));
    await tester.pumpAndSettle();
    // Should slide forward — no "Enter dungeon" CTA, instead the hint card.
    expect(find.text('✨ NEXT UP'), findsOneWidget);
    expect(find.textContaining('Crown Path'), findsOneWidget);
    expect(find.text('Travel here →'), findsOneWidget);
    expect(find.text('Enter dungeon →'), findsNothing);
  });

  testWidgets(
      'next-zone hint also fires on standard zone with a forward neighbour',
      (tester) async {
    final here = _zone(id: 'here', type: 'zone', name: 'Ember Forge');
    final next = _zone(
      id: 'next',
      type: 'dungeon',
      name: 'Sunken Ruins',
      totalXp: 200,
    );
    await tester.pumpWidget(_harness(
      world: _world(
        zones: [here, next],
        currentZoneId: 'here',
        edges: const [
          WorldZoneEdgeModel(
            id: 'e1',
            fromZoneId: 'here',
            toZoneId: 'next',
            distanceKm: 3.5,
            isBidirectional: true,
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('✨ NEXT UP'), findsOneWidget);
    expect(find.textContaining('Sunken Ruins'), findsOneWidget);
    expect(find.text('Dungeon'), findsOneWidget);
    expect(find.text('+200 XP'), findsOneWidget);
    expect(find.textContaining('3.5 km'), findsOneWidget);
    // Misleading "0 / 1 nodes" bar must be gone for this case too.
    expect(find.textContaining('nodes'), findsNothing);
  });

  testWidgets(
      'next-zone hint renders when standing on opened chest with distance pill',
      (tester) async {
    final chest = _zone(id: 'chest', type: 'chest', name: 'Whispering Shrine');
    final next = _zone(
      id: 'next',
      type: 'zone',
      name: 'Mist Pine',
      totalXp: 150,
    );
    final region = _region(
      nodes: [
        _zoneNode(id: 'chest', isChest: true, chestRewardXp: 100)
            ._copyWithChestOpened(true),
      ],
    );
    await tester.pumpWidget(_harness(
      world: _world(
        zones: [chest, next],
        currentZoneId: 'chest',
        currentRegionId: 'region-1',
        edges: const [
          WorldZoneEdgeModel(
            id: 'e1',
            fromZoneId: 'chest',
            toZoneId: 'next',
            distanceKm: 2.5,
            isBidirectional: true,
          ),
        ],
      ),
      region: region,
    ));
    await tester.pumpAndSettle();
    expect(find.text('✨ NEXT UP'), findsOneWidget);
    expect(find.textContaining('Mist Pine'), findsOneWidget);
    expect(find.textContaining('2.5 km'), findsOneWidget);
    expect(find.text('+150 XP'), findsOneWidget);
    expect(find.text('Travel here →'), findsOneWidget);
    // The misleading "0 / 1 nodes" bar from the prior overload is gone.
    expect(find.textContaining('nodes'), findsNothing);
  });

  // CTA wiring (calls Navigator.push → RegionDetailScreen) is intentionally
  // not unit-tested — RegionDetailScreen's initState hits the network and
  // the test framework can't wait that out without runAsync acrobatics. The
  // 6 variant-rendering tests above cover the value of this widget; the
  // 4-line _openWorldDestination helper is verified by analyzer + smoke test.
}

extension _ChestNodeOpened on ZoneNode {
  ZoneNode _copyWithChestOpened(bool opened) => ZoneNode(
        id: id,
        name: name,
        emoji: emoji,
        description: description,
        tier: tier,
        levelRequirement: levelRequirement,
        xpReward: xpReward,
        distanceKm: distanceKm,
        status: status,
        isCrossroads: isCrossroads,
        isBoss: isBoss,
        isChest: isChest,
        isDungeon: isDungeon,
        chestRewardXp: chestRewardXp,
        chestIsOpened: opened,
        dungeonFloorsTotal: dungeonFloorsTotal,
        dungeonFloorsCompleted: dungeonFloorsCompleted,
      );
}
