// Renders the new Home / tab-bar / pull-to-import pieces with real fonts and
// art so they can be compared with the design artifacts by eye.
//
// Not part of the normal suite. Run with:
//   flutter test test/visual/pull_import_showcase_test.dart \
//     --update-goldens --dart-define=SHOWCASE_DIR=/abs/output/dir
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/constants/app_colors.dart';
import 'package:life_level/core/constants/app_icons.dart';
import 'package:life_level/core/shell/widgets/map_orb_button.dart';
import 'package:life_level/core/shell/widgets/shell_tab_bar.dart';
import 'package:life_level/core/theme/app_theme.dart';
import 'package:life_level/features/home/cards/home_happening_now.dart';
import 'package:life_level/features/map/journey/journey_state.dart';
import 'package:life_level/features/sync/models/pending_models.dart';
import 'package:life_level/features/sync/widgets/import_review_sheet.dart';
import 'package:life_level/features/sync/widgets/pull_to_import.dart';
import 'package:life_level/features/sync/widgets/sync_status_pill.dart';

const _outDir = String.fromEnvironment('SHOWCASE_DIR');

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/development/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Black']) {
    final bytes = File('$dir/Roboto-$f.ttf').readAsBytesSync();
    roboto.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(
        File('$dir/MaterialIcons-Regular.otf').readAsBytesSync().buffer)));
  await icons.load();
}

const _assets = [
  AppIcons.mapDestination,
  AppIcons.mapCurrentLocation,
  AppIcons.zoneFirstFork,
  AppIcons.ringBoss,
  AppIcons.rewardTreasureChest,
  AppIcons.zoneTheConvergence,
  AppIcons.rewardGrantItem,
  AppIcons.ringGuild,
  AppIcons.seasonAdventureHub,
  AppIcons.navHome,
  AppIcons.navGear,
  AppIcons.navProfile,
  AppIcons.rewardXpCrystals,
  AppIcons.statEndurance,
  AppIcons.statFlexibility,
  AppIcons.activityRunning,
  AppIcons.activityYoga,
  AppIcons.rewardXpStorm,
  'assets/icons/ring_battle.png',
];

Future<void> _precache(WidgetTester tester) async {
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(Scaffold).first);
    for (final a in _assets) {
      await precacheImage(AssetImage(a), ctx);
    }
  });
  await tester.pump();
}

JourneyOrbState _s(JourneyKind k, Color c, JourneyRing r, String label,
        {double p = 0,
        String? asset,
        IconData? icon,
        bool alert = false,
        int seg = 0,
        int done = 0}) =>
    JourneyOrbState(
      kind: k,
      color: c,
      ring: r,
      progress: p,
      iconAsset: asset,
      icon: icon,
      label: label,
      alert: alert,
      segments: seg,
      segmentsDone: done,
      semantics: label,
    );

final _states = <(String, JourneyOrbState)>[
  (
    'First step',
    _s(JourneyKind.firstStep, AppColors.blue, JourneyRing.dashed, 'Start',
        asset: AppIcons.mapCurrentLocation, alert: true)
  ),
  (
    'Pick next',
    _s(JourneyKind.pickNext, AppColors.blue, JourneyRing.dashed, 'Pick',
        asset: AppIcons.mapDestination, alert: true)
  ),
  (
    'Traveling',
    _s(JourneyKind.traveling, AppColors.blue, JourneyRing.progress, '1.4 km',
        p: .65, asset: AppIcons.mapDestination)
  ),
  (
    'Crossroads',
    _s(JourneyKind.crossroads, AppColors.purple, JourneyRing.split, 'Choose',
        asset: AppIcons.zoneFirstFork, alert: true)
  ),
  (
    'Blocker',
    _s(JourneyKind.blocker, AppColors.red, JourneyRing.progress, 'Blocked',
        p: .7, asset: 'assets/icons/ring_battle.png', alert: true)
  ),
  (
    'Merchant',
    _s(JourneyKind.merchant, AppColors.orange, JourneyRing.progress, 'Merchant',
        p: .55, asset: AppIcons.rewardGrantItem, alert: true)
  ),
  (
    'Story',
    _s(JourneyKind.story, const Color(0xFF38D9C8), JourneyRing.progress,
        'Story',
        p: .3, icon: Icons.chat_bubble_rounded, alert: true)
  ),
  (
    'Boss zone',
    _s(JourneyKind.bossZone, AppColors.red, JourneyRing.progress, 'Boss',
        p: 1, asset: AppIcons.ringBoss, alert: true)
  ),
  (
    'Boss fight',
    _s(JourneyKind.bossRaid, AppColors.red, JourneyRing.progress, '62% · 2d',
        p: .62, asset: AppIcons.ringBoss)
  ),
  (
    'Chest',
    _s(JourneyKind.chest, AppColors.orange, JourneyRing.progress, 'Open',
        p: 1, asset: AppIcons.rewardTreasureChest, alert: true)
  ),
  (
    'Dungeon',
    _s(JourneyKind.dungeon, AppColors.purple, JourneyRing.segments, '2 / 4',
        seg: 4, done: 2, asset: AppIcons.zoneTheConvergence, alert: true)
  ),
  (
    'Level locked',
    _s(JourneyKind.levelLocked, const Color(0xFF8B949E), JourneyRing.progress,
        'Lv 8',
        p: .8, icon: Icons.lock_rounded)
  ),
];

Widget _frame(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark.copyWith(
          textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Roboto'),
        ),
        home: MediaQuery(
          data: const MediaQueryData(
              size: Size(390, 844), disableAnimations: true),
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontFamily: 'Roboto'),
            child:
                Scaffold(backgroundColor: AppColors.backgroundAlt, body: child),
          ),
        ),
      ),
    );

void main() {
  final skip = _outDir.isEmpty;

  setUpAll(() async {
    if (skip) return;
    await _loadFonts();
    goldenFileComparator =
        LocalFileComparator(Uri.file('$_outDir/showcase_test.dart'));
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('orb states', skip: skip, (tester) async {
    await phone(tester);
    await tester.pumpWidget(_frame(Padding(
      padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 22,
        children: [
          for (final (name, st) in _states)
            SizedBox(
              width: 108,
              child: Column(children: [
                ProviderScope(
                  overrides: [journeyOrbStateProvider.overrideWithValue(st)],
                  child: MapOrbButton(open: false, onTap: () {}),
                ),
                const SizedBox(height: 10),
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
        ],
      ),
    )));
    await _precache(tester);
    await tester.pump(const Duration(milliseconds: 950));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('orb_states.png'));
  });

  testWidgets('home bottom: pill, happening now, tab bar, map button',
      skip: skip, (tester) async {
    await phone(tester);
    final events = [
      HappeningEvent(
          id: 'boss',
          icon: AppIcons.ringBoss,
          color: AppColors.red,
          title: 'Forest Warden',
          detail: '62% HP left. Every workout you log deals damage.',
          timeLeft: const Duration(hours: 1, minutes: 42),
          endsLabel: '14:00',
          cta: 'Fight',
          onCta: () {}),
      HappeningEvent(
          id: 'raid',
          icon: AppIcons.ringGuild,
          color: AppColors.red,
          title: 'Frost Wyrm',
          detail: 'Your guild has it at 62% HP.',
          timeLeft: const Duration(days: 2, hours: 1),
          endsLabel: 'Fri 13:30',
          cta: 'Open raid',
          onCta: () {}),
      HappeningEvent(
          id: 'season',
          icon: AppIcons.seasonAdventureHub,
          color: AppColors.blue,
          title: 'Winter Endurance',
          detail: 'Tier 3 of 30. Next reward: Rare mount.',
          timeLeft: const Duration(days: 18),
          endsLabel: '17 Oct',
          cta: 'View season',
          onCta: () {}),
    ];
    await tester.pumpWidget(_frame(
      Stack(children: [
        Positioned.fill(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 60),
            Center(
                child: SyncStatusPill(
                    pendingCount: 2,
                    lastCheckedAt: DateTime.now(),
                    busy: false,
                    onTap: () {})),
            const SizedBox(height: 16),
            Center(
                child: SyncStatusPill(
                    pendingCount: 0,
                    lastCheckedAt:
                        DateTime.now().subtract(const Duration(minutes: 2)),
                    busy: false,
                    onTap: () {})),
            const SizedBox(height: 180),
            const HomeHappeningNow(),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ShellTabBar(
              currentIndex: 0,
              mapOpen: false,
              menuOpen: false,
              onTab: (_) {},
              onMenu: () {}),
        ),
        Positioned(
          bottom: 34,
          left: 195 - kMapOrbSize / 2,
          child: ProviderScope(
            overrides: [
              journeyOrbStateProvider.overrideWithValue(_states[2].$2)
            ],
            child: MapOrbButton(open: false, onTap: () {}),
          ),
        ),
      ]),
      overrides: [happeningEventsProvider.overrideWithValue(events)],
    ));
    await _precache(tester);
    await tester.pump(const Duration(milliseconds: 950));
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('home_bottom.png'));
  });

  testWidgets('review sheet', skip: skip, (tester) async {
    await phone(tester);
    final now = DateTime.now();
    final list = PendingWorkoutList(items: [
      PendingWorkout(
          id: 'run',
          provider: 'strava',
          activityType: 'Running',
          durationMinutes: 38,
          distanceKm: 6.2,
          performedAt: DateTime(now.year, now.month, now.day, 18, 40),
          previewXp: 164,
          previewEndurance: 2,
          previewAgility: 1),
      PendingWorkout(
          id: 'yoga',
          provider: 'healthconnect',
          activityType: 'Yoga',
          durationMinutes: 30,
          performedAt: DateTime(now.year, now.month, now.day, 7, 10),
          previewXp: 148,
          previewFlexibility: 3,
          previewStamina: 1),
      PendingWorkout(
          id: 'dup',
          provider: 'garmin',
          activityType: 'Running',
          durationMinutes: 38,
          distanceKm: 6.2,
          performedAt: DateTime(now.year, now.month, now.day, 18, 41),
          isDuplicate: true,
          duplicateOfProvider: 'strava'),
    ], pendingCount: 2);
    await tester.pumpWidget(_frame(Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => showImportReviewSheet(context, list),
          child: const Text('open'),
        ),
      ),
    )));
    await _precache(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('review_sheet.png'));
  });

  testWidgets('pull rune', skip: skip, (tester) async {
    await phone(tester);
    await tester.pumpWidget(_frame(PullToImport(
      pendingCount: 2,
      busy: false,
      onTrigger: () async {},
      topInset: 40,
      child: ListView(
        physics: PullToImport.physics,
        children: [
          for (var i = 0; i < 20; i++)
            Container(
              height: 64,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14)),
            ),
        ],
      ),
    )));
    await _precache(tester);
    final g = await tester.startGesture(const Offset(195, 300));
    for (var i = 0; i < 20; i++) {
      await g.moveBy(const Offset(0, 22));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('pull_release.png'));
    await g.up();
    await tester.pumpAndSettle();
  });
}
