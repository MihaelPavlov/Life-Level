import 'dart:ui' show PictureRecorder;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/constants/app_colors.dart';
import 'package:life_level/core/constants/app_icons.dart';
import 'package:life_level/core/shell/widgets/map_orb_button.dart';
import 'package:life_level/core/shell/widgets/shell_tab_bar.dart';
import 'package:life_level/features/boss/models/boss_list_item.dart';
import 'package:life_level/features/boss/providers/boss_provider.dart';
import 'package:life_level/features/home/cards/home_happening_now.dart';
import 'package:life_level/features/home/providers/world_progress_provider.dart';
import 'package:life_level/features/map/journey/journey_state.dart';
import 'package:life_level/features/map/models/world_zone_models.dart';

import '../../helpers/unlocks_overrides.dart';

class _EmptyBossListNotifier extends BossListNotifier {
  @override
  Future<List<BossListItem>> build() async => const [];
}

final _emptyWorld = WorldFullData.fromJson({
  'zones': const [],
  'edges': const [],
  'characterLevel': 1,
  'userProgress': {
    'currentZoneId': '',
    'distanceTraveledOnEdge': 0,
  },
});

Widget _app(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        allUnlockedOverride,
        bossListProvider.overrideWith(_EmptyBossListNotifier.new),
        worldProgressProvider.overrideWith((ref) async => _emptyWorld),
        ...overrides,
      ],
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

const _traveling = JourneyOrbState(
  kind: JourneyKind.traveling,
  color: AppColors.blue,
  ring: JourneyRing.progress,
  progress: .65,
  iconAsset: AppIcons.mapDestination,
  label: '1.4 km',
  semantics: 'Traveling, 1.4 km to Whispering Fork',
);

const _crossroads = JourneyOrbState(
  kind: JourneyKind.crossroads,
  color: AppColors.purple,
  ring: JourneyRing.split,
  iconAsset: AppIcons.zoneFirstFork,
  label: 'Choose',
  alert: true,
  semantics: 'Crossroads at Whispering Fork, choose your path',
);

const _bossRaid = JourneyOrbState(
  kind: JourneyKind.bossRaid,
  color: AppColors.red,
  ring: JourneyRing.progress,
  progress: .5,
  label: 'Fight',
  semantics: 'Boss fight, Forest Warden at 50% health',
);

void main() {
  testWidgets('map button shows the journey label and taps through',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(
      MapOrbButton(open: false, onTap: () => taps++),
      overrides: [journeyOrbStateProvider.overrideWithValue(_traveling)],
    ));
    await tester.pump();
    expect(find.text('1.4 km'), findsOneWidget);
    expect(find.text('!'), findsNothing);
    expect(
      find.bySemanticsLabel('Map. Traveling, 1.4 km to Whispering Fork'),
      findsOneWidget,
    );
    await tester.tap(find.byType(MapOrbButton));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });

  testWidgets('an "act now" state shows the dot, hidden while open',
      (tester) async {
    await tester.pumpWidget(_app(
      MapOrbButton(open: false, onTap: () {}),
      overrides: [journeyOrbStateProvider.overrideWithValue(_crossroads)],
    ));
    await tester.pump();
    expect(find.text('Choose'), findsOneWidget);
    expect(find.text('!'), findsOneWidget);

    await tester.pumpWidget(_app(
      MapOrbButton(open: true, onTap: () {}),
      overrides: [journeyOrbStateProvider.overrideWithValue(_crossroads)],
    ));
    await tester.pump();
    expect(find.text('!'), findsNothing);
    // The pulse loops forever; stop the tree before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('boss orb reads as the Map button, not a battle shortcut',
      (tester) async {
    await tester.pumpWidget(_app(
      MapOrbButton(open: false, onTap: () {}),
      overrides: [journeyOrbStateProvider.overrideWithValue(_bossRaid)],
    ));
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        'Map. Boss fight, Forest Warden at 50% health',
      ),
      findsOneWidget,
    );
  });

  test('ring painter handles every ring type', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (final ring in JourneyRing.values) {
      JourneyRingPainter(
        ring: ring,
        color: AppColors.blue,
        progress: .5,
        segments: 4,
        segmentsDone: 2,
      ).paint(canvas, const Size(70, 70));
    }
    recorder.endRecording();
  });

  testWidgets('tab bar: Home, Gear, Map caption, Mode, Profile',
      (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: ShellTabBar(
          currentIndex: 0,
          mapOpen: false,
          onTab: tapped.add,
        ),
      ),
    ));
    for (final label in ['Home', 'Gear', 'Map', 'Mode', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Gear'));
    await tester.tap(find.text('Profile'));
    await tester.tap(find.text('Mode'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tapped, [1, 2, 3]);
  });

  group('happening now', () {
    final events = [
      HappeningEvent(
        id: 'raid',
        icon: AppIcons.ringGuild,
        color: AppColors.red,
        title: 'Frost Wyrm',
        detail: 'Your guild has it at 62% HP.',
        timeLeft: const Duration(days: 2, hours: 1),
        endsLabel: 'Fri 13:30',
        cta: 'Open raid',
        onCta: () {},
      ),
      const HappeningEvent(
        id: 'season',
        icon: AppIcons.seasonAdventureHub,
        color: AppColors.blue,
        title: 'Winter Endurance',
        detail: 'Tier 3 of 30.',
        timeLeft: Duration(days: 18),
        endsLabel: '17 Oct',
        cta: 'View season',
      ),
    ];

    testWidgets('chips switch the focus card', (tester) async {
      await tester.pumpWidget(_app(
        const SingleChildScrollView(child: HomeHappeningNow()),
        overrides: [happeningEventsProvider.overrideWithValue(events)],
      ));
      await tester.pump();
      expect(find.text('HAPPENING NOW'), findsOneWidget);
      expect(find.text('Frost Wyrm · ends Fri 13:30'), findsOneWidget);
      expect(find.text('2d 1h'), findsOneWidget);
      expect(find.text('18 days'), findsOneWidget);

      await tester.tap(find.text('Winter Endurance'));
      // The live dot blinks forever, so pump a fixed time instead of settling.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Winter Endurance · ends 17 Oct'), findsOneWidget);
      expect(find.text('View season'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hidden when nothing is live', (tester) async {
      await tester.pumpWidget(_app(
        const HomeHappeningNow(),
        overrides: [happeningEventsProvider.overrideWithValue(const [])],
      ));
      expect(find.text('HAPPENING NOW'), findsNothing);
    });

    test('time left and end labels', () {
      expect(formatTimeLeft(const Duration(hours: 1, minutes: 42)), '1h 42m');
      expect(formatTimeLeft(const Duration(days: 2, hours: 1)), '2d 1h');
      expect(formatTimeLeft(const Duration(days: 18)), '18 days');
      expect(formatTimeLeft(const Duration(minutes: 5)), '5m');
      final now = DateTime(2026, 9, 29, 12); // a Tuesday
      expect(formatEndsAt(DateTime(2026, 9, 29, 14), now), '14:00');
      expect(formatEndsAt(DateTime(2026, 9, 30, 9, 5), now), 'tomorrow 09:05');
      expect(formatEndsAt(DateTime(2026, 10, 2, 13, 30), now), 'Fri 13:30');
      expect(formatEndsAt(DateTime(2026, 10, 17), now), '17 Oct');
    });
  });
}
