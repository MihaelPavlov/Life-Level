/// One feature in the guided-unlock chain and where the player is with it.
class UnlockState {
  final String key;
  final int order;
  final bool unlocked;
  final DateTime? unlockedAt;
  final bool seen;
  final bool toured;

  const UnlockState({
    required this.key,
    required this.order,
    required this.unlocked,
    this.unlockedAt,
    this.seen = false,
    this.toured = false,
  });

  factory UnlockState.fromJson(Map<String, dynamic> j) => UnlockState(
        key: j['key'] as String,
        order: (j['order'] as num?)?.toInt() ?? 0,
        unlocked: j['unlocked'] as bool? ?? false,
        unlockedAt: j['unlockedAt'] == null
            ? null
            : DateTime.tryParse(j['unlockedAt'] as String),
        seen: j['seen'] as bool? ?? false,
        toured: j['toured'] as bool? ?? false,
      );

  UnlockState copyWith({bool? unlocked, bool? seen, bool? toured}) =>
      UnlockState(
        key: key,
        order: order,
        unlocked: unlocked ?? this.unlocked,
        unlockedAt: unlockedAt,
        seen: seen ?? this.seen,
        toured: toured ?? this.toured,
      );
}

/// The whole chain as the server last reported it.
class UnlocksSnapshot {
  final List<UnlockState> unlocks;

  /// True for [UnlocksSnapshot.open]: nothing is locked and nothing is fresh.
  final bool isFallback;

  const UnlocksSnapshot(this.unlocks) : isFallback = false;

  const UnlocksSnapshot._fallback()
      : unlocks = const [],
        isFallback = true;

  /// Used while the chain loads or when it can't be read: the app stays
  /// fully usable rather than locking a player out.
  static const open = UnlocksSnapshot._fallback();

  factory UnlocksSnapshot.fromJson(Map<String, dynamic> j) {
    final list = (j['unlocks'] as List? ?? const [])
        .map((e) => UnlockState.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return UnlocksSnapshot(list);
  }

  UnlockState? operator [](String key) {
    for (final u in unlocks) {
      if (u.key == key) return u;
    }
    return null;
  }

  /// Unknown keys are open: only features in the chain can be locked.
  bool isUnlocked(String key) {
    if (isFallback) return true;
    return this[key]?.unlocked ?? true;
  }

  /// Unlocked but its tour hasn't run yet: shows the NEW pill.
  bool isFresh(String key) {
    final u = this[key];
    return u != null && u.unlocked && !u.toured;
  }

  /// Unlocks that still owe the player a ceremony, in chain order.
  /// Home never gets one: its tour runs straight after onboarding.
  List<UnlockState> get pendingCeremonies => [
        for (final u in unlocks)
          if (u.unlocked && !u.seen && u.key != 'home') u,
      ];

  List<UnlockState> get toured => [
        for (final u in unlocks)
          if (u.toured) u,
      ];

  UnlocksSnapshot update(String key, UnlockState Function(UnlockState) f) {
    if (isFallback) return this;
    return UnlocksSnapshot([
      for (final u in unlocks) u.key == key ? f(u) : u,
    ]);
  }
}
