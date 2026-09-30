import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/activity/models/activity_models.dart';
import 'package:life_level/features/modes/burn_chain/burn_chain_rules.dart';

final _start = DateTime.utc(2026, 9, 29, 8);

ActivityHistoryDto _workout(String id, int kcal,
        {Duration after = const Duration(hours: 1), int minutes = 30}) =>
    ActivityHistoryDto(
      id: id,
      type: 'Running',
      durationMinutes: minutes,
      distanceKm: 5,
      calories: kcal,
      xpGained: 0,
      strGained: 0,
      endGained: 0,
      agiGained: 0,
      flxGained: 0,
      staGained: 0,
      steps: 0,
      loggedAt: _start.add(after),
    );

BurnChainState _chain(List<ActivityHistoryDto> workouts,
        {Duration now = const Duration(hours: 12), bool collected = false}) =>
    computeBurnChain(
      startedAt: _start,
      collected: collected,
      activities: workouts,
      now: _start.add(now),
    );

void main() {
  test('the example chain: 200, 320 (×2), then 300 breaks it', () {
    final chain = _chain([
      _workout('a', 200, after: const Duration(hours: 1)),
      _workout('b', 320, after: const Duration(hours: 5)),
      _workout('c', 300, after: const Duration(hours: 9)),
    ]);

    expect(chain.phase, BurnChainPhase.ended);
    expect(chain.endReason, BurnChainEndReason.broken);
    expect(chain.links.map((l) => l.kind), [
      ChainLinkKind.base,
      ChainLinkKind.beat,
      ChainLinkKind.breaker,
    ]);
    expect(chain.links.map((l) => l.coins), [40, 128, 60]);
    expect(chain.totalCoins, 228);
    expect(chain.bar, 320);
  });

  test('workouts after the breaker do not count', () {
    final chain = _chain([
      _workout('a', 200, after: const Duration(hours: 1)),
      _workout('b', 150, after: const Duration(hours: 2)),
      _workout('c', 900, after: const Duration(hours: 3)),
    ]);
    expect(chain.links.length, 2);
    expect(chain.totalCoins, 70);
  });

  test('burning the same as the bar breaks the chain', () {
    final chain = _chain([
      _workout('a', 200, after: const Duration(hours: 1)),
      _workout('b', 200, after: const Duration(hours: 2)),
    ]);
    expect(chain.links.last.kind, ChainLinkKind.breaker);
  });

  test('stays live while unbroken and inside the window', () {
    final chain = _chain([
      _workout('a', 200, after: const Duration(hours: 1)),
      _workout('b', 250, after: const Duration(hours: 2)),
    ]);
    expect(chain.phase, BurnChainPhase.live);
    expect(chain.bar, 250);
    expect(chain.timeLeft(_start.add(const Duration(hours: 12))),
        const Duration(hours: 12));
  });

  test('ends when the 24h window is over', () {
    final chain = _chain(
      [_workout('a', 200, after: const Duration(hours: 1))],
      now: const Duration(hours: 25),
    );
    expect(chain.phase, BurnChainPhase.ended);
    expect(chain.endReason, BurnChainEndReason.timeUp);
    expect(chain.totalCoins, 40);
  });

  test('ignores workouts before the start, after the window, or too short', () {
    final chain = _chain([
      _workout('before', 999, after: const Duration(hours: -1)),
      _workout('short', 999,
          after: const Duration(hours: 1), minutes: kBurnChainMinMinutes - 1),
      _workout('late', 999, after: const Duration(hours: 25)),
      _workout('ok', 200, after: const Duration(hours: 2)),
    ]);
    expect(chain.links.map((l) => l.activityId), ['ok']);
  });

  test('orders workouts by time, not by list order', () {
    final chain = _chain([
      _workout('second', 320, after: const Duration(hours: 5)),
      _workout('first', 200, after: const Duration(hours: 1)),
    ]);
    expect(chain.links.map((l) => l.activityId), ['first', 'second']);
    expect(chain.links.last.kind, ChainLinkKind.beat);
  });

  test('not started or collected is idle', () {
    expect(
      computeBurnChain(
              startedAt: null,
              collected: false,
              activities: const [],
              now: _start)
          .phase,
      BurnChainPhase.idle,
    );
    expect(_chain(const [], collected: true).phase, BurnChainPhase.idle);
  });
}
