import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/season/widgets/season_theme.dart';

void main() {
  test('season XP uses the real XP crystal artwork', () {
    expect(
      seasonIconAsset('reward_xp_sparkle'),
      'assets/icons/reward_xp_crystals.png',
    );
  });

  testWidgets('locked reward keeps its asset and adds a lock badge',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SeasonRewardAsset(
            iconKey: 'reward_xp_sparkle',
            size: 40,
            locked: true,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,
        'assets/icons/reward_xp_crystals.png');
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });
}
