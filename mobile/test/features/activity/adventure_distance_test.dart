import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/activity/activity_result_sheet.dart';
import 'package:life_level/features/activity/models/activity_models.dart';
import 'package:life_level/features/integrations/models/integration_models.dart';
import 'package:life_level/features/sync/models/pending_models.dart';

void main() {
  test('activity multipliers match the Adventure km balance table', () {
    expect(ActivityType.running.adventureDistanceMultiplier, 1);
    expect(ActivityType.walking.adventureDistanceMultiplier, 1);
    expect(ActivityType.hiking.adventureDistanceMultiplier, 1);
    expect(ActivityType.cycling.adventureDistanceMultiplier, 0.25);
    expect(ActivityType.swimming.adventureDistanceMultiplier, 4);
    expect(ActivityType.gym.adventureDistanceMultiplier, 0);
    expect(ActivityType.yoga.adventureDistanceMultiplier, 0);
    expect(ActivityType.climbing.adventureDistanceMultiplier, 0);
  });

  test('manual result parses Adventure km and supports an older response', () {
    Map<String, dynamic> response([Map<String, dynamic> extra = const {}]) => {
          'activityId': 'activity-1',
          'xpGained': 100,
          ...extra,
        };

    expect(
      LogActivityResult.fromJson(response({'adventureDistanceKm': 5.25}))
          .adventureDistanceKm,
      5.25,
    );
    expect(LogActivityResult.fromJson(response()).adventureDistanceKm, 0);
  });

  test('sync and pending import totals parse Adventure km', () {
    expect(
      SyncResult.fromJson({
        'imported': 2,
        'skipped': 0,
        'errors': <String>[],
        'totalAdventureDistanceKm': 13,
      }).summary,
      'Synced 2 activities · 13 Adventure km',
    );

    expect(
      ImportPendingResult.fromJson({
        'imported': <dynamic>[],
        'totalAdventureDistanceKm': 7.5,
      }).totalAdventureDistanceKm,
      7.5,
    );
  });

  testWidgets('completion sheet shows earned Adventure km', (tester) async {
    const result = LogActivityResult(
      activityId: 'activity-1',
      adventureDistanceKm: 5,
      xpGained: 100,
      strGained: 0,
      endGained: 2,
      agiGained: 1,
      flxGained: 0,
      staGained: 0,
      leveledUp: false,
      newLevel: null,
      completedQuests: [],
      streakUpdated: false,
      currentStreak: 0,
      allDailyQuestsCompleted: false,
      bonusXpAwarded: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(
          home: Scaffold(body: ActivityResultSheet(result: result))),
    );
    await tester.pumpAndSettle();

    expect(find.text('+5 Adventure km'), findsOneWidget);
  });
}
