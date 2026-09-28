import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/character/models/character_profile.dart';
import 'package:life_level/features/gear/widgets/gear_stats_row.dart';

const _profile = CharacterProfile(
  username: 'Hero',
  avatarEmoji: '🧙',
  className: 'Warrior',
  classEmoji: '⚔️',
  rank: 'Novice',
  level: 5,
  xp: 100,
  xpForCurrentLevel: 0,
  xpForNextLevel: 200,
  strength: 12,
  endurance: 10,
  agility: 8,
  flexibility: 7,
  stamina: 11,
  weeklyRuns: 2,
  weeklyDistanceKm: 8,
  weeklyXpEarned: 300,
  currentStreak: 4,
  availableStatPoints: 0,
  power: 125,
  attack: 32,
  health: 210,
  defense: 18,
);

void main() {
  testWidgets('gear combat stats open resource information dialogs',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: GearStatsRow(profile: _profile)),
        ),
      ),
    );

    const cases = [
      ('power', 'Power'),
      ('attack', 'Strength'),
      ('health', 'Health'),
      ('defense', 'Shield'),
    ];
    for (final (key, title) in cases) {
      await tester.tap(find.byKey(ValueKey('gear-$key-info')));
      await tester.pump();
      expect(find.text(title), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
    }
  });
}
