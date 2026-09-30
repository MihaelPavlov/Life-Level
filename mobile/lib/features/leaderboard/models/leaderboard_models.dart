/// Who a leaderboard ranks.
enum LeaderboardScope {
  global('Global'),
  region('Region'),
  guild('Guild');

  final String label;
  const LeaderboardScope(this.label);
}

/// What a leaderboard ranks by. Power and streak never reset; the rest are
/// weekly and reset on Monday.
enum LeaderboardMetric {
  power('Power'),
  xp('XP'),
  km('Km'),
  boss('Boss'),
  streak('Streak');

  final String label;
  const LeaderboardMetric(this.label);

  /// A score as shown on a row, e.g. `1,240 XP`.
  String format(double v) => switch (this) {
        LeaderboardMetric.power => leaderboardFmt(v.round()),
        LeaderboardMetric.xp => '${leaderboardFmt(v.round())} XP',
        LeaderboardMetric.km => '${v.toStringAsFixed(1)} km',
        LeaderboardMetric.boss =>
          v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '${v.round()}',
        LeaderboardMetric.streak => '${v.round()} d',
      };

  /// A gap to the next player, e.g. `95 power`.
  String gap(double v) => switch (this) {
        LeaderboardMetric.power => '${leaderboardFmt(v.ceil())} power',
        LeaderboardMetric.xp => '${leaderboardFmt(v.ceil())} XP',
        LeaderboardMetric.km => '${v.toStringAsFixed(1)} km',
        LeaderboardMetric.boss => '${leaderboardFmt(v.ceil())} dmg',
        LeaderboardMetric.streak =>
          v.ceil() == 1 ? '1 day' : '${v.ceil()} days',
      };
}

String leaderboardFmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String? avatarEmoji;
  final int level;
  final String? className;
  final double score;
  final bool isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.avatarEmoji,
    required this.level,
    required this.className,
    required this.score,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank'] as int,
        userId: j['userId'] as String,
        username: j['username'] as String? ?? '',
        avatarEmoji: j['avatarEmoji'] as String?,
        level: j['level'] as int? ?? 1,
        className: j['className'] as String?,
        score: (j['score'] as num?)?.toDouble() ?? 0,
        isMe: j['isMe'] as bool? ?? false,
      );
}

/// The viewer's own pinned row. [rank] is null when they are not on the board.
class LeaderboardMe {
  final int? rank;
  final double score;
  final int total;
  final String? nextUsername;
  final double? gapToNext;

  const LeaderboardMe({
    required this.rank,
    required this.score,
    required this.total,
    this.nextUsername,
    this.gapToNext,
  });

  factory LeaderboardMe.fromJson(Map<String, dynamic> j) => LeaderboardMe(
        rank: j['rank'] as int?,
        score: (j['score'] as num?)?.toDouble() ?? 0,
        total: j['total'] as int? ?? 0,
        nextUsername: j['nextUsername'] as String?,
        gapToNext: (j['gapToNext'] as num?)?.toDouble(),
      );
}

/// The rank-up chest: one stacked reward per player you passed.
class LeaderboardChest {
  final int stack;
  final int coins;
  final int gems;

  const LeaderboardChest(
      {required this.stack, required this.coins, required this.gems});

  static const empty = LeaderboardChest(stack: 0, coins: 0, gems: 0);

  factory LeaderboardChest.fromJson(Map<String, dynamic> j) => LeaderboardChest(
        stack: j['stack'] as int? ?? 0,
        coins: j['coins'] as int? ?? 0,
        gems: j['gems'] as int? ?? 0,
      );
}

class LeaderboardBoard {
  final LeaderboardScope scope;
  final LeaderboardMetric metric;
  final bool available;
  final String? contextName;
  final DateTime? resetsAt;
  final List<LeaderboardEntry> entries;
  final LeaderboardMe me;
  final LeaderboardChest chest;

  const LeaderboardBoard({
    required this.scope,
    required this.metric,
    required this.available,
    required this.contextName,
    required this.resetsAt,
    required this.entries,
    required this.me,
    required this.chest,
  });

  factory LeaderboardBoard.fromJson(Map<String, dynamic> j) => LeaderboardBoard(
        scope: LeaderboardScope.values.byName(j['scope'] as String),
        metric: LeaderboardMetric.values.byName(j['metric'] as String),
        available: j['available'] as bool? ?? true,
        contextName: j['contextName'] as String?,
        resetsAt: j['resetsAtUtc'] == null
            ? null
            : DateTime.parse(j['resetsAtUtc'] as String).toUtc(),
        entries: [
          for (final e in (j['entries'] as List? ?? const []))
            LeaderboardEntry.fromJson(e as Map<String, dynamic>),
        ],
        me: LeaderboardMe.fromJson(j['me'] as Map<String, dynamic>),
        chest: LeaderboardChest.fromJson(j['chest'] as Map<String, dynamic>),
      );
}

class LeaderboardPass {
  final String username;
  final String? avatarEmoji;
  final int coins;
  final int gems;

  const LeaderboardPass(
      {required this.username,
      required this.avatarEmoji,
      required this.coins,
      required this.gems});

  factory LeaderboardPass.fromJson(Map<String, dynamic> j) => LeaderboardPass(
        username: j['username'] as String? ?? '',
        avatarEmoji: j['avatarEmoji'] as String?,
        coins: j['coins'] as int? ?? 0,
        gems: j['gems'] as int? ?? 0,
      );
}

class LeaderboardChestOpened {
  final int coins;
  final int gems;
  final List<LeaderboardPass> passes;

  const LeaderboardChestOpened(
      {required this.coins, required this.gems, required this.passes});

  factory LeaderboardChestOpened.fromJson(Map<String, dynamic> j) =>
      LeaderboardChestOpened(
        coins: j['coins'] as int? ?? 0,
        gems: j['gems'] as int? ?? 0,
        passes: [
          for (final p in (j['passes'] as List? ?? const []))
            LeaderboardPass.fromJson(p as Map<String, dynamic>),
        ],
      );
}
