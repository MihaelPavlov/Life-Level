import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/features/boss/widgets/boss_hit_fx.dart';

// Captures the latest frame the scope hands to its builder.
BossHitFrame? _last;

Widget _host(String id, int hp, {bool tickers = true}) => MaterialApp(
      home: Scaffold(
        body: TickerMode(
          enabled: tickers,
          child: BossHitScope(
            hitId: id,
            hp: hp,
            maxHp: 1000,
            builder: (context, hit, key) {
              _last = hit;
              return BossHitPortrait(
                hit: hit,
                portraitKey: key,
                child: const SizedBox(width: 60, height: 60),
              );
            },
          ),
        ),
      ),
    );

void main() {
  testWidgets('first sighting records HP without playing a hit',
      (tester) async {
    await tester.pumpWidget(_host('boss-a', 800));
    expect(_last!.active, isFalse);
    expect(BossHitMemory.seen('boss-a'), 800);
  });

  testWidgets('HP drop plays slash + ember burn, then settles',
      (tester) async {
    await tester.pumpWidget(_host('boss-b', 800));
    await tester.pumpWidget(_host('boss-b', 600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(_last!.active, isTrue);
    expect(_last!.barHp, 600, reason: 'fill snaps after the slash lands');
    expect(_last!.emberHp, inInclusiveRange(600, 800));
    expect(_last!.shownHp, inInclusiveRange(600, 800));

    await tester.pumpAndSettle();
    expect(_last!.active, isFalse);
    expect(_last!.shownHp, 600);
    expect(_last!.emberHp, isNull);
  });

  testWidgets('hit waits while tickers are muted, then plays once visible',
      (tester) async {
    await tester.pumpWidget(_host('boss-c', 900));
    await tester.pumpWidget(_host('boss-c', 500, tickers: false));
    await tester.pump();
    expect(_last!.active, isFalse);
    expect(BossHitMemory.seen('boss-c'), 900,
        reason: 'unseen drop must not be consumed');

    await tester.pumpWidget(_host('boss-c', 500));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_last!.active, isTrue);
    expect(BossHitMemory.seen('boss-c'), 500);
    await tester.pumpAndSettle();
  });

  testWidgets('a drop already seen elsewhere does not replay',
      (tester) async {
    BossHitMemory.markSeen('boss-d', 300);
    await tester.pumpWidget(_host('boss-d', 300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(_last!.active, isFalse);
  });
}
