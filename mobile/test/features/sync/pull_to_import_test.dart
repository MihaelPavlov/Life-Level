import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/integrations/models/integration_models.dart';
import 'package:life_level/features/sync/models/pending_models.dart';
import 'package:life_level/features/sync/pull_import_flow.dart';
import 'package:life_level/features/sync/providers/pending_workouts_provider.dart';
import 'package:life_level/features/sync/services/pending_workouts_service.dart';
import 'package:life_level/features/sync/widgets/import_review_sheet.dart';
import 'package:life_level/features/sync/widgets/pull_to_import.dart';
import 'package:life_level/features/sync/widgets/sync_status_pill.dart';
import 'package:shared_preferences/shared_preferences.dart';

PendingWorkout _w(String id,
        {String type = 'Running',
        String provider = 'strava',
        int xp = 164,
        bool dup = false,
        double? km = 6.2}) =>
    PendingWorkout(
      id: id,
      provider: provider,
      activityType: type,
      durationMinutes: 38,
      distanceKm: km,
      performedAt: DateTime.now().subtract(const Duration(hours: 1)),
      isDuplicate: dup,
      duplicateOfProvider: dup ? 'strava' : null,
      previewXp: xp,
      previewEndurance: type == 'Running' ? 2 : 0,
      previewFlexibility: type == 'Yoga' ? 3 : 0,
    );

class _FakeService extends PendingWorkoutsService {
  PendingWorkoutList next;
  List<ExternalActivityDto>? staged;
  List<String>? importedIds;
  bool fail = false;
  bool failStrava = false;
  int stravaRefreshes = 0;
  _FakeService(this.next);

  @override
  Future<PendingWorkoutList> list() async {
    if (fail) throw Exception('offline');
    return next;
  }

  @override
  Future<PendingWorkoutList> stage(List<ExternalActivityDto> activities) async {
    if (fail) throw Exception('offline');
    staged = activities;
    return next;
  }

  @override
  Future<PendingWorkoutList> stageStrava() async {
    stravaRefreshes++;
    if (failStrava) throw const StravaStageException('Strava unavailable');
    return next;
  }

  @override
  Future<ImportPendingResult> import(List<String> ids) async {
    importedIds = ids;
    return ImportPendingResult(
      imported: [
        for (final id in ids)
          ImportedWorkout(
              pendingId: id,
              activityType: 'Running',
              provider: 'strava',
              distanceKm: 6.2,
              durationMinutes: 38,
              xpGained: 164,
              endurance: 2),
      ],
      totalXp: 164 * ids.length,
      totalDistanceKm: 6.2 * ids.length,
      remainingPending: next.pendingCount - ids.length,
    );
  }
}

class _FakeReader implements LocalWorkoutReader {
  List<ExternalActivityDto>? toReturn;
  int staged = 0;
  _FakeReader([this.toReturn]);
  @override
  Future<List<ExternalActivityDto>?> readForStaging() async => toReturn;
  @override
  Future<void> markStaged() async => staged++;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('pending workouts provider', () {
    test('check stages phone workouts, then keeps the queue', () async {
      final service = _FakeService(PendingWorkoutList(
          items: [_w('a'), _w('b', dup: true)], pendingCount: 1));
      final reader = _FakeReader([
        ExternalActivityDto(
          provider: 'HealthConnect',
          externalId: 'healthconnect:1',
          activityType: 'Yoga',
          durationMinutes: 30,
          performedAt: DateTime.now().toUtc(),
        ),
      ]);
      final c = ProviderContainer(overrides: [
        pendingWorkoutsServiceProvider.overrideWithValue(service),
        localWorkoutReaderProvider.overrideWithValue(reader),
      ]);
      addTearDown(c.dispose);

      final list = await c.read(pendingWorkoutsProvider.notifier).check();

      expect(service.staged, hasLength(1));
      expect(service.stravaRefreshes, 1);
      expect(reader.staged, 1);
      expect(list.pending, hasLength(1));
      final state = c.read(pendingWorkoutsProvider);
      expect(state.pendingCount, 1);
      expect(state.lastCheckedAt, isNotNull);
      expect(state.checking, isFalse);
    });

    test('check without phone workouts just reads the queue', () async {
      final service = _FakeService(PendingWorkoutList.empty);
      final c = ProviderContainer(overrides: [
        pendingWorkoutsServiceProvider.overrideWithValue(service),
        localWorkoutReaderProvider.overrideWithValue(_FakeReader(const [])),
      ]);
      addTearDown(c.dispose);

      await c.read(pendingWorkoutsProvider.notifier).check();

      expect(service.staged, isNull);
      expect(service.stravaRefreshes, 1);
      expect(c.read(pendingWorkoutsProvider).pendingCount, 0);
    });

    test('quiet check does not fetch Strava history', () async {
      final service = _FakeService(PendingWorkoutList.empty);
      final c = ProviderContainer(overrides: [
        pendingWorkoutsServiceProvider.overrideWithValue(service),
        localWorkoutReaderProvider.overrideWithValue(_FakeReader(const [])),
      ]);
      addTearDown(c.dispose);

      await c.read(pendingWorkoutsProvider.notifier).checkQuietly();

      expect(service.stravaRefreshes, 0);
    });

    test('check rethrows when offline, checkQuietly does not', () async {
      final service = _FakeService(PendingWorkoutList.empty)..fail = true;
      final c = ProviderContainer(overrides: [
        pendingWorkoutsServiceProvider.overrideWithValue(service),
        localWorkoutReaderProvider.overrideWithValue(_FakeReader(null)),
      ]);
      addTearDown(c.dispose);

      await expectLater(
          c.read(pendingWorkoutsProvider.notifier).check(), throwsException);
      await c.read(pendingWorkoutsProvider.notifier).checkQuietly();
      expect(c.read(pendingWorkoutsProvider).checking, isFalse);
    });

    test('import removes the imported workouts from the queue', () async {
      final service = _FakeService(
          PendingWorkoutList(items: [_w('a'), _w('b')], pendingCount: 2));
      var refreshed = 0;
      final c = ProviderContainer(overrides: [
        pendingWorkoutsServiceProvider.overrideWithValue(service),
        localWorkoutReaderProvider.overrideWithValue(_FakeReader(const [])),
        pendingImportRefreshProvider.overrideWithValue(() => refreshed++),
      ]);
      addTearDown(c.dispose);
      await c.read(pendingWorkoutsProvider.notifier).check();

      final result =
          await c.read(pendingWorkoutsProvider.notifier).import(['a']);

      expect(service.importedIds, ['a']);
      expect(result.totalXp, 164);
      expect(result.statGains.first.key, 'END');
      final state = c.read(pendingWorkoutsProvider);
      expect(state.pendingCount, 1);
      expect(state.list.items.map((w) => w.id), ['b']);
      expect(state.importing, isFalse);
      expect(refreshed, 1);
    });
  });

  group('review sheet', () {
    Future<ImportReviewChoice?> open(
        WidgetTester tester, PendingWorkoutList list) async {
      ImportReviewChoice? choice;
      var closed = false;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  choice = await showImportReviewSheet(context, list);
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      addTearDown(() => expect(closed, isTrue));
      return choice;
    }

    testWidgets('lists workouts, marks duplicates and totals the XP',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await open(
          tester,
          PendingWorkoutList(items: [
            _w('run'),
            _w('yoga',
                type: 'Yoga', provider: 'healthconnect', xp: 148, km: null),
            _w('dup', provider: 'garmin', dup: true),
          ], pendingCount: 2));

      expect(find.text('2 new workouts'), findsOneWidget);
      expect(find.text('From Strava and Health Connect'), findsOneWidget);
      expect(find.text('Duplicate · skipped'), findsOneWidget);
      expect(find.text('Same workout as Strava'), findsOneWidget);
      expect(find.text('Import 2 · +312 XP'), findsOneWidget);

      // Untick the yoga session: the total follows.
      await tester.tap(find.text('Yoga'));
      await tester.pumpAndSettle();
      expect(find.text('Import 1 · +164 XP'), findsOneWidget);

      await tester.tap(find.text('Import 1 · +164 XP'));
      await tester.pumpAndSettle();
    });

    testWidgets('Later closes without importing', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await open(
          tester, PendingWorkoutList(items: [_w('run')], pendingCount: 1));
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(find.text('1 new workout'), findsNothing);
    });
  });

  group('status pill', () {
    test('ago label', () {
      final now = DateTime(2026, 9, 29, 12);
      expect(SyncStatusPill.agoLabel(null, now), 'Pull down to sync');
      expect(
          SyncStatusPill.agoLabel(
              now.subtract(const Duration(seconds: 20)), now),
          'Synced just now');
      expect(
          SyncStatusPill.agoLabel(
              now.subtract(const Duration(minutes: 2)), now),
          'Synced 2m ago');
      expect(
          SyncStatusPill.agoLabel(now.subtract(const Duration(hours: 5)), now),
          'Synced 5h ago');
    });

    testWidgets('shows the orange pill when workouts wait', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SyncStatusPill(
            pendingCount: 2,
            lastCheckedAt: DateTime.now(),
            busy: false,
            onTap: () => taps++,
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2 new workouts · pull down'), findsOneWidget);
      await tester.tap(find.text('2 new workouts · pull down'));
      expect(taps, 1);
    });
  });

  group('pull gesture', () {
    Future<int> pull(WidgetTester tester, double distance) async {
      var fired = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PullToImport(
            pendingCount: 2,
            busy: false,
            onTrigger: () async => fired++,
            topInset: 40,
            child: ListView(
              physics: PullToImport.physics,
              children: [
                for (var i = 0; i < 30; i++)
                  SizedBox(height: 60, child: Text('row $i'))
              ],
            ),
          ),
        ),
      ));
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('row 2')));
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(Offset(0, distance / 20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      if (distance > kPullToImportThreshold * 2) {
        expect(find.text('Release to import'), findsOneWidget);
      }
      await gesture.up();
      await tester.pumpAndSettle();
      return fired;
    }

    testWidgets('a full pull and release checks for workouts', (tester) async {
      expect(await pull(tester, 420), 1);
    });

    testWidgets('a short pull springs back without checking', (tester) async {
      expect(await pull(tester, 60), 0);
    });
  });

  group('whole flow', () {
    // Toasts animate a countdown until they leave, so never settle on them.
    Future<void> toastFrames(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<(ProviderContainer, _FakeService, WidgetRef?)> host(
        WidgetTester tester, PendingWorkoutList list,
        {bool offline = false}) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final service = _FakeService(list)..fail = offline;
      final c = ProviderContainer(overrides: [
        pendingWorkoutsServiceProvider.overrideWithValue(service),
        localWorkoutReaderProvider.overrideWithValue(_FakeReader(const [])),
        pendingImportRefreshProvider.overrideWithValue(() {}),
      ]);
      addTearDown(c.dispose);
      WidgetRef? captured;
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
                size: Size(390, 844), disableAnimations: true),
            child: Consumer(builder: (context, ref, _) {
              captured = ref;
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => runPullImportFlow(context, ref),
                    child: const Text('pull'),
                  ),
                ),
              );
            }),
          ),
        ),
      ));
      return (c, service, captured);
    }

    testWidgets('check, review, import, recap', (tester) async {
      final (c, service, _) = await host(
          tester, PendingWorkoutList(items: [_w('run')], pendingCount: 1));
      await tester.tap(find.text('pull'));
      await tester.pumpAndSettle();
      expect(find.text('1 new workout'), findsOneWidget);

      await tester.tap(find.text('Import 1 · +164 XP'));
      await toastFrames(tester);
      expect(service.importedIds, ['run']);
      expect(find.text('Imported 1 workout'), findsOneWidget);
      expect(c.read(pendingWorkoutsProvider).pendingCount, 0);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('empty queue says up to date', (tester) async {
      await host(tester, PendingWorkoutList.empty);
      await tester.tap(find.text('pull'));
      await toastFrames(tester);
      expect(find.text('You’re up to date'), findsOneWidget);
      expect(find.text('1 new workout'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('offline keeps the workouts and says so', (tester) async {
      await host(tester, PendingWorkoutList.empty, offline: true);
      await tester.tap(find.text('pull'));
      await toastFrames(tester);
      expect(find.text('You’re offline'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Strava failure shows the provider error', (tester) async {
      final (_, service, _) = await host(tester, PendingWorkoutList.empty);
      service.failStrava = true;
      await tester.tap(find.text('pull'));
      await toastFrames(tester);
      expect(find.text('Strava sync failed'), findsOneWidget);
      expect(find.text('Strava unavailable'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Later leaves them queued', (tester) async {
      final (_, service, _) = await host(
          tester, PendingWorkoutList(items: [_w('run')], pendingCount: 1));
      await tester.tap(find.text('pull'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Later'));
      await toastFrames(tester);
      expect(service.importedIds, isNull);
      expect(find.text('Saved for later'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
