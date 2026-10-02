import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/activity/models/activity_models.dart';
import 'package:life_level/features/activity/providers/activity_provider.dart';
import 'package:life_level/features/character/models/character_profile.dart';
import 'package:life_level/features/profile/profile_sections.dart';

CharacterProfile _profile({int points = 0, List<String> bonuses = const []}) =>
    CharacterProfile(
      username: 'Kael',
      avatarEmoji: null,
      className: 'Archer',
      classEmoji: null,
      rank: 'Warrior',
      level: 12,
      xp: 2040,
      xpForCurrentLevel: 1500,
      xpForNextLevel: 3000,
      strength: 12,
      endurance: 18,
      agility: 42,
      flexibility: 7,
      stamina: 11,
      weeklyRuns: 0,
      weeklyDistanceKm: 0,
      weeklyXpEarned: 0,
      currentStreak: 0,
      availableStatPoints: points,
      talents: TalentSummary(
        ownedCount: bonuses.length,
        catalogCount: 16,
        totalLevels: bonuses.length,
        coins: 0,
        gems: 0,
        talentCrystals: 0,
        strBonus: 0,
        endBonus: 0,
        agiBonus: 0,
        flxBonus: 0,
        staBonus: 0,
        effectLines: bonuses,
      ),
    );

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

void main() {
  testWidgets('stat "+" buttons appear only with points to spend',
      (tester) async {
    await tester.pumpWidget(_wrap(ProfileStatsSection(profile: _profile())));
    expect(find.text('STR'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    await tester
        .pumpWidget(_wrap(ProfileStatsSection(profile: _profile(points: 2))));
    expect(find.byIcon(Icons.add_rounded), findsNWidgets(5));
    expect(find.text(' points to spend'), findsOneWidget);
  });

  testWidgets('talent bonuses show 4 and offer the rest in a sheet',
      (tester) async {
    final lines = List.generate(6, (i) => 'Bonus $i');
    await tester.pumpWidget(_wrap(
        ProfileTalentBonusesSection(talents: _profile(bonuses: lines).talents!)));
    expect(find.text('Bonus 3'), findsOneWidget);
    expect(find.text('Bonus 4'), findsNothing);
    expect(find.text('See all 6 bonuses'), findsOneWidget);

    await tester.pumpWidget(_wrap(ProfileTalentBonusesSection(
        talents: _profile(bonuses: lines.take(4).toList()).talents!)));
    expect(find.textContaining('See all'), findsNothing);
  });

  testWidgets('last 12 weeks counts this period and opens the history',
      (tester) async {
    final now = DateTime.now().toUtc();
    final calendar = ActivityCalendar(longestRunKm: 12.4, days: [
      ActivityCalendarDay(
          date: DateTime.utc(now.year, now.month, now.day),
          workouts: 2,
          distanceKm: 5,
          xp: 200),
      ActivityCalendarDay(
          date: DateTime.utc(now.year, now.month, now.day)
              .subtract(const Duration(days: 20)),
          workouts: 1,
          distanceKm: 8,
          xp: 150),
      // Older than 12 weeks: only in the history sheet.
      ActivityCalendarDay(
          date: DateTime.utc(now.year, now.month, now.day)
              .subtract(const Duration(days: 150)),
          workouts: 1,
          distanceKm: 3,
          xp: 90),
    ]);
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(
      const ProfileWeeksSection(),
      overrides: [
        activityCalendarProvider.overrideWith((ref) async => calendar),
      ],
    ));
    await tester.pump();
    expect(find.text('3 workouts'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);

    await tester.tap(find.text('3 workouts'));
    await tester.pumpAndSettle();
    expect(find.text('Workout history'), findsOneWidget);
    expect(find.textContaining('4 workouts since'), findsOneWidget);

    await tester.tap(find.text('By month'));
    await tester.pumpAndSettle();
    expect(find.textContaining('XP'), findsWidgets);
  });
}
