import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/core/constants/app_icons.dart';
import 'package:life_level/features/map/models/world_map_models.dart';
import 'package:life_level/features/map/widgets/zone_node_tile.dart';

ZoneNode _boss(ZoneNodeStatus status) => ZoneNode(
      id: 'boss',
      name: 'Stone Titan',
      emoji: '',
      description: '',
      tier: 9,
      levelRequirement: 1,
      xpReward: 0,
      distanceKm: 4,
      status: status,
      isCrossroads: false,
      isBoss: true,
      isChest: false,
      isDungeon: false,
    );

Widget _host(ZoneNode node) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            height: 110, // the trail's row height
            child: ZoneNodeBubble(
              node: node,
              nextRegionName: 'Ashen Caldera',
            ),
          ),
        ),
      ),
    );

bool _showsFullArt(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .any((i) =>
        i.image is AssetImage &&
        (i.image as AssetImage).assetName == AppIcons.bossStoneTitan);

void main() {
  testWidgets('before you reach the boss it stays hidden in its circle',
      (tester) async {
    await tester.pumpWidget(_host(_boss(ZoneNodeStatus.available)));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('???'), findsOneWidget);
    expect(find.text('Region boss · reach him to reveal'), findsOneWidget);
    expect(find.text('Stone Titan'), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.text('YOU ARE HERE'), findsNothing);
    expect(_showsFullArt(tester), isFalse);
  });

  testWidgets('standing on the boss zone shows the full boss art',
      (tester) async {
    await tester.pumpWidget(_host(_boss(ZoneNodeStatus.active)));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Stone Titan'), findsOneWidget);
    expect(find.text('Boss · Unlocks Ashen Caldera'), findsOneWidget);
    expect(find.text('YOU ARE HERE'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(_showsFullArt(tester), isTrue);
    expect(tester.takeException(), isNull); // no row overflow
  });

  testWidgets('arriving reveals the boss: circle out, art grows in',
      (tester) async {
    await tester.pumpWidget(_host(_boss(ZoneNodeStatus.next)));
    await tester.pump(const Duration(milliseconds: 700));
    expect(_showsFullArt(tester), isFalse);

    await tester.pumpWidget(_host(_boss(ZoneNodeStatus.active)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_showsFullArt(tester), isTrue);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.text('Stone Titan'), findsOneWidget);
  });

  testWidgets('a beaten boss stays revealed', (tester) async {
    await tester.pumpWidget(_host(_boss(ZoneNodeStatus.completed)));
    await tester.pump(const Duration(milliseconds: 700));
    expect(_showsFullArt(tester), isTrue);
    expect(find.text('???'), findsNothing);
  });
}
