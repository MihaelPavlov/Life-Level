import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/boss/models/boss_damage_history.dart';
import 'package:life_level/features/boss/models/boss_list_item.dart';
import 'package:life_level/features/boss/replay/boss_replay.dart';
import 'package:life_level/features/boss/replay/boss_seen_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

BossListItem _boss({int hpDealt = 0, int youHp = 240, bool defeated = false}) =>
    BossListItem(
      id: 'warden',
      name: 'Forest Warden',
      icon: '',
      maxHp: 1200,
      rewardXp: 500,
      timerDays: 7,
      isMini: false,
      region: 'Forest',
      nodeName: 'Dawn Camp',
      levelRequirement: 3,
      canFight: true,
      activated: true,
      hpDealt: hpDealt,
      isDefeated: defeated,
      isExpired: false,
      currentPlayerHp: youHp,
      playerMaxHp: 240,
    );

final _t0 = DateTime(2026, 10, 1, 8);

BossDamageHistoryItem _turn(int minutes, int bossAfter, int youAfter,
        {int dealt = 300, int taken = 45, bool kill = false, bool ko = false}) =>
    BossDamageHistoryItem(
      activityId: 'a$minutes',
      activityType: 'Running',
      durationMinutes: 30,
      distanceKm: 5,
      calories: 300,
      damage: dealt,
      damageTaken: taken,
      playerHpAfter: youAfter,
      playerDefeated: ko,
      loggedAt: _t0.add(Duration(minutes: minutes)),
      turnId: 't$minutes',
      bossHpAfter: bossAfter,
      bossMaxHp: 1200,
      damageBlocked: 12,
      bossDefeated: kill,
    );

void main() {
  test('only turns after the seen cursor replay, from the seen HP', () {
    final history = [_turn(20, 580, 150), _turn(10, 880, 195)]; // newest first
    final rec = BossSeenRecord(
        turnAt: _t0.add(const Duration(minutes: 10)), bossHp: 880, youHp: 195);

    final r = BossReplayFinder.build(_boss(hpDealt: 620), history, rec, _t0)!;

    expect(r.turns.map((t) => t.bossHpAfter), [580]);
    expect(r.startBossHp, 880);
    expect(r.startYouHp, 195);
    expect(r.turns.single.blocked, 12);
  });

  test('nothing after the cursor means no replay', () {
    final rec = BossSeenRecord(
        turnAt: _t0.add(const Duration(hours: 1)), bossHp: 880, youHp: 195);
    expect(
        BossReplayFinder.build(_boss(), [_turn(10, 880, 195)], rec, _t0), isNull);
  });

  test('a fresh install replays only the last few minutes', () {
    final now = _t0.add(const Duration(minutes: 40));
    final history = [_turn(35, 280, 105), _turn(5, 880, 195)];

    final r = BossReplayFinder.build(_boss(), history, null, now)!;

    expect(r.turns.length, 1);
    expect(r.startBossHp, 880, reason: 'starts after the older, seen turn');
    expect(r.startYouHp, 195);
  });

  test('a kill and a knock-out are flagged', () {
    final rec = BossSeenRecord(turnAt: _t0, bossHp: 300, youHp: 50);
    final kill = BossReplayFinder.build(
        _boss(defeated: true), [_turn(5, 0, 50, kill: true, taken: 0)], rec, _t0)!;
    expect(kill.finished, isTrue);

    final ko = BossReplayFinder.build(
        _boss(), [_turn(5, 150, 0, ko: true, taken: 50)], rec, _t0)!;
    expect(ko.endsKnockedOut, isTrue);
  });

  test('a kill already watched elsewhere does not replay', () {
    final rec = BossSeenRecord(turnAt: _t0, bossHp: 0, youHp: 50);
    expect(
        BossReplayFinder.build(
            _boss(defeated: true), [_turn(5, 0, 50, kill: true)], rec, _t0),
        isNull);
  });

  test('four or more exchanges fold into one combined hit plus the last three',
      () {
    final turns = [
      for (var i = 0; i < 5; i++)
        BossReplayTurn(
          activityType: 'Running',
          dealt: 100,
          taken: 10,
          blocked: 2,
          bossHpAfter: 1000 - i * 100,
          youHpAfter: 230 - i * 10,
          at: _t0.add(Duration(minutes: i)),
        ),
    ];
    final played = collapseTurns(turns);
    expect(played.length, 4);
    expect(played.first.count, 2);
    expect(played.first.dealt, 200);
    expect(played.first.bossHpAfter, 900);
  });

  test('the seen store survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BossSeenStore.instance..resetForTest();
    store.put('warden', BossSeenRecord(turnAt: _t0, bossHp: 880, youHp: 195));
    await Future<void>.delayed(Duration.zero);

    store.resetForTest();
    expect(store['warden'], isNull);
    await store.load();
    expect(store['warden']?.bossHp, 880);
    expect(store['warden']?.youHp, 195);
  });
}
