import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/features/character/models/character_profile.dart';
import 'package:life_level/features/character/providers/character_provider.dart';
import 'package:life_level/features/titles/models/title_models.dart';
import 'package:life_level/features/titles/providers/titles_provider.dart';
import 'package:life_level/features/titles/services/titles_service.dart';
import 'package:life_level/features/titles/titles_ranks_screen.dart';
import 'package:life_level/features/titles/widgets/title_equip_flight.dart';

Map<String, dynamic> _title(String id, String name, {bool equipped = false}) =>
    {
      'id': id,
      'emoji': '🏅',
      'name': name,
      'unlockCondition': 'Sample condition',
      'isEarned': true,
      'isEquipped': equipped,
    };

TitlesAndRanksResponse _data() => TitlesAndRanksResponse.fromJson({
      'activeTitleEmoji': '🏅',
      'activeTitleName': 'Marathoner',
      'rankProgression': {
        'currentRank': 'Warrior',
        'bossesDefeated': 2,
        'bossesRequiredForNextRank': 3,
        'bossesRemainingForNextRank': 1,
        'nextRank': 'Veteran',
      },
      'earnedTitles': [
        _title('t1', 'Marathoner', equipped: true),
        _title('t2', 'Dawn Chaser'),
      ],
      'lockedTitles': <Map<String, dynamic>>[],
    });

class _FakeTitlesService implements TitlesService {
  final bool fail;
  final equipped = <String>[];
  _FakeTitlesService({this.fail = false});

  @override
  Future<TitlesAndRanksResponse> getTitlesAndRanks() async {
    final base = _data();
    if (equipped.isEmpty) return base;
    final id = equipped.last;
    final earned = base.earnedTitles
        .map((t) => t.copyWith(isEquipped: t.id == id))
        .toList();
    final active = earned.firstWhere((t) => t.id == id);
    return base.copyWith(
      earnedTitles: earned,
      activeTitleName: active.name,
      activeTitleEmoji: active.emoji,
    );
  }

  @override
  Future<TitleDto> equipTitle(String titleId) async {
    if (fail) throw Exception('network down');
    equipped.add(titleId);
    return _data().earnedTitles.firstWhere((t) => t.id == titleId);
  }
}

class _FakeCharacterNotifier extends CharacterNotifier {
  @override
  Future<CharacterProfile> build() async => CharacterProfile.fromJson({
        'username': 'Kestrel',
        'rank': 'Warrior',
        'level': 14,
        'xp': 18420,
        'xpForCurrentLevel': 18000,
        'xpForNextLevel': 21000,
        'strength': 10,
        'endurance': 12,
        'agility': 9,
        'flexibility': 5,
        'stamina': 11,
        'weeklyRuns': 3,
        'weeklyDistanceKm': 21.5,
        'weeklyXpEarned': 1200,
        'currentStreak': 4,
      });
}

Widget _harness(_FakeTitlesService service) => ProviderScope(
      overrides: [
        titlesServiceProvider.overrideWithValue(service),
        characterProfileProvider.overrideWith(_FakeCharacterNotifier.new),
      ],
      child: const MaterialApp(home: TitlesRanksScreen()),
    );

Finder _equipButton() => find.widgetWithText(TextButton, 'Equip');

Future<void> _pumpScreen(WidgetTester tester, _FakeTitlesService service) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_harness(service));
  await tester.pumpAndSettle();
  await tester.ensureVisible(_equipButton());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('equip flies the title into the nameplate, then commits',
      (tester) async {
    final service = _FakeTitlesService();
    await _pumpScreen(tester, service);

    expect(find.text('EQUIPPED'), findsOneWidget);
    await tester.tap(_equipButton());
    await tester.pump(); // flight overlay inserted
    await tester.pump(const Duration(milliseconds: 200));

    // In the air: the ghost pill is flying, nothing committed yet, and
    // Equip is disabled so a second tap can't start another flight.
    expect(find.byType(TitleGhostPill), findsOneWidget);
    expect(service.equipped, isEmpty);
    final button = tester.widget<TextButton>(_equipButton());
    expect(button.onPressed, isNull);

    // Landing commits the equip.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.equipped, ['t2']);
    await tester.pumpAndSettle();

    expect(find.byType(TitleGhostPill), findsNothing);
    // Nameplate shows the new title; the badge moved to its card.
    expect(find.text('Dawn Chaser'), findsNWidgets(2));
    expect(find.text('EQUIPPED'), findsOneWidget);
    final card = find.ancestor(
      of: find.text('EQUIPPED'),
      matching: find.byType(Row),
    );
    expect(
        find.descendant(of: card.first, matching: find.text('Dawn Chaser')),
        findsOneWidget);
  });

  testWidgets('failed equip restores the old title and shows an error',
      (tester) async {
    final service = _FakeTitlesService(fail: true);
    await _pumpScreen(tester, service);

    await tester.tap(_equipButton());
    // Flight + failed save; the error toast counts down for 5 s, so pump a
    // fixed time rather than settling (which would outlast the toast).
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining("Couldn't equip Dawn Chaser"), findsOneWidget);
    // Marathoner is back on the nameplate and still on its card.
    expect(find.text('Marathoner'), findsNWidgets(2));
    expect(_equipButton(), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
