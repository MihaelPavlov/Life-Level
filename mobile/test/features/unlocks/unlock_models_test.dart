import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/unlocks/models/unlock_catalog.dart';
import 'package:life_level/features/unlocks/models/unlock_models.dart';

UnlocksSnapshot _parse(List<Map<String, dynamic>> rows) =>
    UnlocksSnapshot.fromJson({'unlocks': rows});

Map<String, dynamic> _row(String key, int order,
        {bool unlocked = true, bool seen = false, bool toured = false}) =>
    {
      'key': key,
      'order': order,
      'unlocked': unlocked,
      'unlockedAt': unlocked ? '2026-09-30T10:00:00Z' : null,
      'seen': seen,
      'toured': toured,
    };

void main() {
  test('parses the chain in order', () {
    final s = _parse([
      _row('achievements', 1),
      _row('home', 0, seen: true, toured: true),
    ]);
    expect(s.unlocks.map((u) => u.key), ['home', 'achievements']);
    expect(s['achievements']!.unlockedAt, DateTime.utc(2026, 9, 30, 10));
  });

  test('locked, fresh and pending ceremonies', () {
    final s = _parse([
      _row('home', 0),
      _row('achievements', 1),
      _row('map', 2, seen: true),
      _row('gear', 3, seen: true, toured: true),
      _row('guild', 8, unlocked: false),
    ]);
    expect(s.isUnlocked('guild'), isFalse);
    expect(s.isUnlocked('gear'), isTrue);
    expect(s.isFresh('map'), isTrue);
    expect(s.isFresh('gear'), isFalse);
    expect(s.isFresh('guild'), isFalse);
    // Home never gets a ceremony; its tour runs straight after onboarding.
    expect(s.pendingCeremonies.map((u) => u.key), ['achievements']);
  });

  test('the open fallback locks nothing and owes nothing', () {
    const s = UnlocksSnapshot.open;
    for (final key in kUnlockCatalog.keys) {
      expect(s.isUnlocked(key), isTrue, reason: key);
      expect(s.isFresh(key), isFalse, reason: key);
    }
    expect(s.pendingCeremonies, isEmpty);
  });

  test('keys outside the chain are never locked', () {
    final s = _parse([_row('home', 0)]);
    expect(s.isUnlocked('season'), isTrue);
  });

  test('update patches one feature', () {
    final s = _parse([_row('achievements', 1)])
        .update('achievements', (u) => u.copyWith(seen: true, toured: true));
    expect(s.isFresh('achievements'), isFalse);
    expect(s.pendingCeremonies, isEmpty);
  });

  test('every catalog entry has a tour-able name and hint', () {
    for (final m in kUnlockCatalog.values) {
      expect(m.name, isNotEmpty);
      expect(m.lockedHint, isNotEmpty);
    }
  });
}
