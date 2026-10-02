import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the player last saw of one boss fight: the newest combat turn and
/// both HP values on screen at that moment.
@immutable
class BossSeenRecord {
  final DateTime turnAt;
  final int bossHp;

  /// Player HP last shown; -1 when it was never shown (older records).
  final int youHp;

  const BossSeenRecord({
    required this.turnAt,
    required this.bossHp,
    this.youHp = -1,
  });

  BossSeenRecord copyWith({DateTime? turnAt, int? bossHp, int? youHp}) =>
      BossSeenRecord(
        turnAt: turnAt ?? this.turnAt,
        bossHp: bossHp ?? this.bossHp,
        youHp: youHp ?? this.youHp,
      );

  Map<String, dynamic> toJson() => {
        't': turnAt.toUtc().toIso8601String(),
        'b': bossHp,
        'y': youHp,
      };

  static BossSeenRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final t = DateTime.tryParse('${raw['t']}');
    if (t == null) return null;
    return BossSeenRecord(
      turnAt: t,
      bossHp: (raw['b'] as num?)?.toInt() ?? 0,
      youHp: (raw['y'] as num?)?.toInt() ?? -1,
    );
  }
}

/// The boss HP (and player HP) the player has actually seen, per boss,
/// kept across app restarts. Home's Map button draws these values, and a
/// replay advances them turn by turn, so every exchange plays exactly once,
/// wherever the player looks first.
class BossSeenStore extends ChangeNotifier {
  BossSeenStore._();
  static final instance = BossSeenStore._();

  static const _prefix = 'boss_seen_v1:';
  final Map<String, BossSeenRecord> _records = {};
  SharedPreferences? _prefs;

  /// Loads saved records. Call once before the first frame.
  Future<void> load() async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(_prefix)) continue;
        final raw = prefs.getString(key);
        if (raw == null) continue;
        final rec = BossSeenRecord.fromJson(jsonDecode(raw));
        if (rec != null) _records[key.substring(_prefix.length)] = rec;
      }
    } catch (_) {
      // A broken store only means one extra replay; never block start-up.
    }
  }

  BossSeenRecord? operator [](String bossId) => _records[bossId];

  /// Saves [rec] for [bossId] and redraws everything that shows it.
  void put(String bossId, BossSeenRecord rec) {
    final old = _records[bossId];
    if (old != null &&
        old.turnAt == rec.turnAt &&
        old.bossHp == rec.bossHp &&
        old.youHp == rec.youHp) {
      return;
    }
    _records[bossId] = rec;
    notifyListeners();
    _save(bossId, rec);
  }

  /// Updates only the values given, keeping the rest.
  void update(String bossId, {DateTime? turnAt, int? bossHp, int? youHp}) {
    final old = _records[bossId] ??
        BossSeenRecord(turnAt: turnAt ?? DateTime.now(), bossHp: bossHp ?? 0);
    put(bossId, old.copyWith(turnAt: turnAt, bossHp: bossHp, youHp: youHp));
  }

  /// Forgets everything (logout: the next account starts clean).
  Future<void> clear() async {
    _records.clear();
    notifyListeners();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_prefix)) await prefs.remove(key);
    }
  }

  Future<void> _save(String bossId, BossSeenRecord rec) async {
    try {
      final prefs = _prefs ??= await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$bossId', jsonEncode(rec.toJson()));
    } catch (_) {}
  }

  @visibleForTesting
  void resetForTest() {
    _records.clear();
    _prefs = null;
  }
}

/// Rebuilds watchers whenever a seen value changes.
final bossSeenStoreProvider =
    ChangeNotifierProvider<BossSeenStore>((_) => BossSeenStore.instance);
