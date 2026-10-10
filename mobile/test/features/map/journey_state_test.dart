import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/constants/app_colors.dart';
import 'package:life_level/features/boss/models/boss_list_item.dart';
import 'package:life_level/features/boss/replay/boss_seen_store.dart';
import 'package:life_level/features/map/journey/journey_state.dart';
import 'package:life_level/features/map/models/world_map_models.dart';
import 'package:life_level/features/map/models/world_zone_models.dart';

Map<String, dynamic> _zone(String id, String type,
        {int tier = 1, bool levelMet = true, int levelRequirement = 1}) =>
    {
      'id': id,
      'name': 'Zone $id',
      'type': type,
      'tier': tier,
      'levelRequirement': levelRequirement,
      'userState': {
        'isUnlocked': true,
        'isLevelMet': levelMet,
        'isCurrentZone': false,
        'isDestination': false,
      },
    };

WorldFullData _world({
  required List<Map<String, dynamic>> zones,
  List<Map<String, dynamic>> edges = const [],
  String currentZoneId = '',
  String? destinationZoneId,
  String? currentEdgeId,
  double travelled = 0,
}) =>
    WorldFullData.fromJson({
      'zones': zones,
      'edges': edges,
      'characterLevel': 5,
      'userProgress': {
        'currentZoneId': currentZoneId,
        'destinationZoneId': destinationZoneId,
        'currentEdgeId': currentEdgeId,
        'distanceTraveledOnEdge': travelled,
      },
    });

RegionDetail _region({
  List<Map<String, dynamic>> nodes = const [],
  List<Map<String, dynamic>> encounters = const [],
}) =>
    RegionDetail.fromJson({
      'id': 'forest',
      'name': 'Forest of Endurance',
      'nodes': nodes,
      'encounters': encounters,
    });

JourneyOrbState _resolve(
  WorldFullData world, {
  RegionDetail? region,
  BossListItem? boss,
  DungeonState? dungeon,
  double xp = .4,
}) =>
    resolveJourneyOrb(
      activeBoss: boss,
      worldAsync: AsyncValue.data(world),
      region: region,
      dungeonState: dungeon,
      xpProgress: xp,
    );

void main() {
  test('no zone yet → pulsing "Start"', () {
    final s = _resolve(_world(zones: const []));
    expect(s.kind, JourneyKind.firstStep);
    expect(s.label, 'Start');
    expect(s.alert, isTrue);
    expect(s.ring, JourneyRing.dashed);
  });

  test('loading and error states', () {
    expect(
      resolveJourneyOrb(
        activeBoss: null,
        worldAsync: const AsyncValue.loading(),
        region: null,
        dungeonState: null,
        xpProgress: 0,
      ).kind,
      JourneyKind.loading,
    );
    final err = resolveJourneyOrb(
      activeBoss: null,
      worldAsync: const AsyncValue.error('boom', StackTrace.empty),
      region: null,
      dungeonState: null,
      xpProgress: 0,
    );
    expect(err.kind, JourneyKind.error);
    expect(err.label, 'Retry');
  });

  test('traveling fills the ring with km and counts down', () {
    final s = _resolve(_world(
      zones: [_zone('a', 'standard'), _zone('b', 'crossroads', tier: 2)],
      edges: [
        {
          'id': 'e1',
          'fromZoneId': 'a',
          'toZoneId': 'b',
          'distanceKm': 4.0,
          'isBidirectional': true
        },
      ],
      currentZoneId: 'a',
      destinationZoneId: 'b',
      currentEdgeId: 'e1',
      travelled: 2.6,
    ));
    expect(s.kind, JourneyKind.traveling);
    expect(s.progress, closeTo(.65, .001));
    expect(s.label, '1.4 km');
    expect(s.color, AppColors.blue);
    expect(s.alert, isFalse);
  });

  test('a blocker on the edge wins over traveling', () {
    final s = _resolve(
      _world(
        zones: [_zone('a', 'standard'), _zone('b', 'boss', tier: 2)],
        edges: [
          {
            'id': 'e1',
            'fromZoneId': 'a',
            'toZoneId': 'b',
            'distanceKm': 6.4,
            'isBidirectional': true
          },
        ],
        currentZoneId: 'a',
        destinationZoneId: 'b',
        currentEdgeId: 'e1',
        travelled: 3,
      ),
      region: _region(encounters: [
        {
          'id': 'enc1',
          'fromZoneId': 'a',
          'toZoneId': 'b',
          't': .5,
          'type': 'blocker',
          'blocker': {
            'name': 'Bramble Brute',
            'blockedZoneName': 'Zone b',
            'maxHp': 600,
            'currentHp': 420,
            'retreatsInSeconds': 3600,
            'rewards': <String>[],
          },
        },
      ]),
    );
    expect(s.kind, JourneyKind.blocker);
    expect(s.progress, closeTo(.7, .001));
    expect(s.label, 'Blocked');
    expect(s.alert, isTrue);
  });

  test('merchant and story encounters', () {
    RegionDetail enc(String type) => _region(encounters: [
          {
            'id': 'x',
            'fromZoneId': 'a',
            'toZoneId': 'b',
            't': .3,
            'type': type
          },
        ]);
    final world = _world(
      zones: [_zone('a', 'standard'), _zone('b', 'standard', tier: 2)],
      edges: [
        {
          'id': 'e1',
          'fromZoneId': 'a',
          'toZoneId': 'b',
          'distanceKm': 5.0,
          'isBidirectional': true
        },
      ],
      currentZoneId: 'a',
      destinationZoneId: 'b',
      currentEdgeId: 'e1',
      travelled: 1,
    );
    expect(_resolve(world, region: enc('merchant')).kind, JourneyKind.merchant);
    final story = _resolve(world, region: enc('story'));
    expect(story.kind, JourneyKind.story);
    expect(story.progress, closeTo(.2, .001));
  });

  test('crossroads shows the split ring and asks to choose', () {
    final s = _resolve(_world(
      zones: [_zone('fork', 'crossroads')],
      currentZoneId: 'fork',
      destinationZoneId: 'fork',
    ));
    expect(s.kind, JourneyKind.crossroads);
    expect(s.ring, JourneyRing.split);
    expect(s.label, 'Choose');
    expect(s.alert, isTrue);
  });

  test('boss zone, chest and opened chest', () {
    final boss = _resolve(_world(
        zones: [_zone('lair', 'boss')],
        currentZoneId: 'lair',
        destinationZoneId: 'lair'));
    expect(boss.kind, JourneyKind.bossZone);
    expect(boss.color, AppColors.red);

    final world = _world(
        zones: [_zone('c', 'chest')],
        currentZoneId: 'c',
        destinationZoneId: 'c');
    final chest = _resolve(world,
        region: _region(nodes: [
          {'id': 'c', 'chestIsOpened': false},
        ]));
    expect(chest.kind, JourneyKind.chest);
    expect(chest.label, 'Open');
    final opened = _resolve(world,
        region: _region(nodes: [
          {'id': 'c', 'chestIsOpened': true},
        ]));
    expect(opened.kind, JourneyKind.chestOpened);
    expect(opened.alert, isFalse);
  });

  test('dungeon splits the ring into floors', () {
    final s = _resolve(
      _world(
          zones: [_zone('d', 'dungeon')],
          currentZoneId: 'd',
          destinationZoneId: 'd'),
      dungeon: DungeonState.fromJson({
        'zoneId': 'd',
        'status': 'inProgress',
        'floors': [
          for (final st in ['completed', 'completed', 'active', 'locked'])
            {'id': st + st.length.toString(), 'status': st},
        ],
      }),
    );
    expect(s.kind, JourneyKind.dungeon);
    expect(s.ring, JourneyRing.segments);
    expect(s.segments, 4);
    expect(s.segmentsDone, 2);
    expect(s.label, '2 / 4');
  });

  test('a defeated or distant ready boss cannot replace the current dungeon',
      () {
    final world = _world(
      zones: [_zone('old-boss', 'boss'), _zone('ruins', 'dungeon')],
      currentZoneId: 'ruins',
    );
    final defeated = BossListItem.fromJson({
      'id': 'forest-sentinel',
      'name': 'Forest Sentinel',
      'icon': '',
      'maxHp': 800,
      'rewardXp': 100,
      'timerDays': 0,
      'activated': true,
      'isDefeated': true,
      'hpDealt': 800,
      'worldZoneId': 'old-boss',
    });
    final distant = BossListItem.fromJson({
      'id': 'distant-boss',
      'name': 'Distant Boss',
      'icon': '',
      'maxHp': 1000,
      'rewardXp': 100,
      'timerDays': 0,
      'canFight': true,
      'worldZoneId': 'old-boss',
    });

    final selected = selectJourneyBoss([defeated, distant], world);
    expect(selected, isNull);
    expect(_resolve(world, boss: selected).kind, JourneyKind.dungeon);
    expect(
        selectJourneyBoss(
            [defeated, distant],
            _world(
                zones: [_zone('old-boss', 'boss')], currentZoneId: 'old-boss')),
        distant);

    final active = BossListItem.fromJson({
      'id': 'active-raid',
      'name': 'Active Raid',
      'icon': '',
      'maxHp': 1000,
      'rewardXp': 100,
      'timerDays': 1,
      'activated': true,
    });
    expect(selectJourneyBoss([defeated, distant, active], world), active);
  });

  group('a kill the player has not watched yet', () {
    final now = DateTime.utc(2026, 10, 9, 12);
    final world = _world(
      zones: [_zone('warden', 'boss'), _zone('next', 'standard')],
      currentZoneId: 'warden',
    );
    BossListItem killed({DateTime? at}) => BossListItem.fromJson({
          'id': 'warden',
          'name': 'Forest Warden',
          'icon': '',
          'maxHp': 1000,
          'rewardXp': 100,
          'timerDays': 7,
          'activated': true,
          'isDefeated': true,
          'hpDealt': 1000,
          'worldZoneId': 'warden',
          'defeatedAt': (at ?? now.subtract(const Duration(minutes: 2)))
              .toIso8601String(),
        });
    BossSeenRecord seenAt(int bossHp) =>
        BossSeenRecord(turnAt: now, bossHp: bossHp, youHp: 80);

    test('keeps its fight on the Map button until the replay shows it', () {
      final boss = killed();
      final selected = selectJourneyBoss([boss], world,
          seenOf: (_) => seenAt(500), now: now);
      expect(selected, boss);
      final s = resolveJourneyOrb(
        activeBoss: selected,
        bossSeen: seenAt(500),
        worldAsync: AsyncData(world),
        region: null,
        dungeonState: null,
        xpProgress: 0,
      );
      expect(s.kind, JourneyKind.bossRaid);
      expect(s.progress, closeTo(.5, .001));
    });

    test('moves on once the kill was watched', () {
      expect(
          selectJourneyBoss([killed()], world,
              seenOf: (_) => seenAt(0), now: now),
          isNull);
    });

    test('moves on when the fight was never seen in progress', () {
      expect(
          selectJourneyBoss([killed()], world, seenOf: (_) => null, now: now),
          isNull);
    });

    test('moves on after the replay window', () {
      final old = killed(at: now.subtract(const Duration(hours: 25)));
      expect(
          selectJourneyBoss([old], world, seenOf: (_) => seenAt(500), now: now),
          isNull);
    });

    test('the boss being replayed stays up even after its HP reaches 0', () {
      final boss = killed();
      expect(
          selectJourneyBoss([boss], world,
              seenOf: (_) => seenAt(0), playingBossId: 'warden', now: now),
          boss);
    });
  });

  test('standing on a finished zone suggests the next one', () {
    final world = _world(
      zones: [_zone('camp', 'standard'), _zone('next', 'standard', tier: 2)],
      edges: [
        {
          'id': 'e',
          'fromZoneId': 'camp',
          'toZoneId': 'next',
          'distanceKm': 3.0,
          'isBidirectional': true
        },
      ],
      currentZoneId: 'camp',
    );
    final s = _resolve(world);
    expect(s.kind, JourneyKind.pickNext);
    expect(s.label, 'Pick');
    expect(s.alert, isTrue);
  });

  test('a level-gated next zone shows XP toward the level', () {
    final world = _world(
      zones: [
        _zone('camp', 'standard'),
        _zone('pass', 'standard',
            tier: 2, levelMet: false, levelRequirement: 8),
      ],
      edges: [
        {
          'id': 'e',
          'fromZoneId': 'camp',
          'toZoneId': 'pass',
          'distanceKm': 5.0,
          'isBidirectional': true
        },
      ],
      currentZoneId: 'camp',
    );
    final s = _resolve(world, xp: .8);
    expect(s.kind, JourneyKind.levelLocked);
    expect(s.label, 'Lv 8');
    expect(s.progress, .8);
    expect(s.icon, Icons.lock_rounded);
  });

  test('an active boss raid wins over everything', () {
    final boss = BossListItem.fromJson({
      'id': 'b1',
      'name': 'Forest Warden',
      'icon': '',
      'maxHp': 6000,
      'rewardXp': 600,
      'timerDays': 7,
      'activated': true,
      'hpDealt': 2280,
      'startedAt': DateTime.now().toUtc().toIso8601String(),
    });
    final s = _resolve(
      _world(zones: [_zone('fork', 'crossroads')], currentZoneId: 'fork'),
      boss: boss,
    );
    expect(s.kind, JourneyKind.bossRaid);
    expect(s.progress, closeTo(.62, .001));
    expect(s.label, isNot(contains('%')));
    expect(s.label, isNotEmpty);
    expect(s.alert, isFalse);
  });

  test('boss zone does not put an alert on the center Map button', () {
    final s = _resolve(
      _world(zones: [_zone('boss', 'boss')], currentZoneId: 'boss'),
    );
    expect(s.kind, JourneyKind.bossZone);
    expect(s.label, 'Boss');
    expect(s.alert, isFalse);
  });

  test('ready boss Map button shows full player HP and ignores stale zero', () {
    final boss = BossListItem.fromJson({
      'id': 'ready-boss',
      'name': 'Forest Warden',
      'icon': '',
      'maxHp': 6000,
      'rewardXp': 600,
      'timerDays': 0,
      'canFight': true,
      'activated': false,
      'hpDealt': 0,
      'currentPlayerHp': 80,
      'playerMaxHp': 80,
    });
    final s = resolveJourneyOrb(
      activeBoss: boss,
      bossSeen: BossSeenRecord(
        turnAt: DateTime(2026),
        bossHp: 0,
        youHp: 0,
      ),
      worldAsync: AsyncData(
        _world(zones: [_zone('boss', 'boss')], currentZoneId: 'boss'),
      ),
      region: null,
      dungeonState: null,
      xpProgress: 0,
    );

    expect(s.kind, JourneyKind.bossRaid);
    expect(s.progress, 1);
    expect(s.secondaryProgress, 1);
    expect(s.secondaryColor, AppColors.green);
    expect(s.semantics, contains('you at 100%'));
  });

  test('a blocker fight splits the ring with the player HP', () {
    final linked = BossListItem.fromJson({
      'id': 'brute-boss',
      'name': 'Bramble Brute',
      'icon': '',
      'maxHp': 600,
      'rewardXp': 100,
      'timerDays': 0,
      'canFight': true,
      'activated': true,
      'hpDealt': 180,
      'currentPlayerHp': 60,
      'playerMaxHp': 240,
    });
    final s = resolveJourneyOrb(
      activeBoss: null,
      bosses: [linked],
      seenOf: (_) => null,
      worldAsync: AsyncValue.data(_world(
        zones: [_zone('a', 'standard'), _zone('b', 'boss', tier: 2)],
        edges: [
          {
            'id': 'e1',
            'fromZoneId': 'a',
            'toZoneId': 'b',
            'distanceKm': 6.4,
            'isBidirectional': true
          },
        ],
        currentZoneId: 'a',
        destinationZoneId: 'b',
        currentEdgeId: 'e1',
        travelled: 3,
      )),
      region: _region(encounters: [
        {
          'id': 'enc1',
          'fromZoneId': 'a',
          'toZoneId': 'b',
          't': .5,
          'type': 'blocker',
          'blocker': {
            'name': 'Bramble Brute',
            'blockedZoneName': 'Zone b',
            'maxHp': 600,
            'currentHp': 420,
            'retreatsInSeconds': 3600,
            'rewards': <String>[],
            'bossId': 'brute-boss',
          },
        },
      ]),
      dungeonState: null,
      xpProgress: 0,
    );

    expect(s.kind, JourneyKind.blocker);
    expect(s.progress, closeTo(.7, .001));
    expect(s.secondaryProgress, closeTo(.25, .001));
    expect(s.secondaryColor, AppColors.red, reason: 'a quarter HP reads red');
  });
}
