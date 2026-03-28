import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../character/character_service.dart';
import '../character/models/character_profile.dart';
import '../character/models/xp_history_entry.dart';

// ── static stat metadata ──────────────────────────────────────────────────────
class _StatMeta {
  final String key;
  final String label;
  final String emoji;
  final Color color;
  final String description;
  final List<String> activities;
  final List<String> perks;
  const _StatMeta(
    this.key,
    this.label,
    this.emoji,
    this.color,
    this.description,
    this.activities,
    this.perks,
  );
}

const _kStrMeta = _StatMeta(
  'STR', 'Strength', '💪', AppColors.red,
  'Raw physical power. Determines how much damage you deal in battles and '
  'how quickly you break through boss health bars.',
  ['🏋️ Gym workouts', '🪨 Climbing', '🚵 Weighted cycling'],
  ['⚔️ +Damage vs bosses', '🪖 Equip heavy armour', '🔓 Unlock Warrior zones'],
);

const _kEndMeta = _StatMeta(
  'END', 'Endurance', '🏃', AppColors.blue,
  'Your ability to sustain effort over time. High endurance lets you travel '
  'further on the map and complete longer quest chains.',
  ['🏃 Running', '🚴 Cycling', '🏊 Swimming'],
  ['🗺️ +Map distance per km', '📜 Access long-distance quests', '🔓 Unlock Ocean of Balance'],
);

const _kAgiMeta = _StatMeta(
  'AGI', 'Agility', '⚡', Color(0xFF38d9c8),
  'Speed and reaction time. Agility boosts your dodge chance in raids and '
  'increases XP gained from pace-based activities.',
  ['🏃 Running (pace-focused)', '🚴 Cycling sprints', '⛹️ HIIT'],
  ['🎯 +Dodge chance in raids', '⚡ +XP for high-pace runs', '🔓 Unlock sprint challenges'],
);

const _kFlxMeta = _StatMeta(
  'FLX', 'Flexibility', '🧘', AppColors.purple,
  'Mobility and recovery. Flexibility reduces injury cooldowns and '
  'gives bonus XP on rest days when you do active recovery.',
  ['🧘 Yoga', '🤸 Stretching', '💆 Mobility sessions'],
  ['💤 -Recovery time after boss fights', '✨ +XP on rest-day workouts', '🔓 Unlock Zen titles'],
);

const _kStaMeta = _StatMeta(
  'STA', 'Stamina', '❤️', AppColors.orange,
  'Overall staying power across all activity types. Stamina grows from '
  'consistency — it feeds every other stat and your streak multiplier.',
  ['🏋️ Any gym session', '🧘 Any workout', '📅 Daily login streak'],
  ['🔥 +Streak XP multiplier', '❤️ +Max HP in raids', '🔓 Required for Champion rank'],
);

// ── runtime stat model (meta + live value) ────────────────────────────────────
class _StatData {
  final _StatMeta meta;
  final int value;
  const _StatData(this.meta, this.value);

  String get key => meta.key;
  String get label => meta.label;
  String get emoji => meta.emoji;
  Color get color => meta.color;
  String get description => meta.description;
  List<String> get activities => meta.activities;
  List<String> get perks => meta.perks;
}

List<_StatData> _buildStats(CharacterProfile p) => [
  _StatData(_kStrMeta, p.strength),
  _StatData(_kEndMeta, p.endurance),
  _StatData(_kAgiMeta, p.agility),
  _StatData(_kFlxMeta, p.flexibility),
  _StatData(_kStaMeta, p.stamina),
];

// ── rank → accent colour ──────────────────────────────────────────────────────
Color _rankColor(String rank) {
  switch (rank.toLowerCase()) {
    case 'warrior':
      return AppColors.blue;
    case 'veteran':
      return AppColors.purple;
    case 'champion':
      return AppColors.orange;
    case 'legend':
      return AppColors.red;
    default:
      return AppColors.textSecondary; // novice
  }
}

// ── XP format helper ──────────────────────────────────────────────────────────
String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

// ── local colour aliases ──────────────────────────────────────────────────────
const _kBg       = AppColors.background;
const _kSurface  = AppColors.surface;
const _kSurface2 = AppColors.surfaceElevated;
const _kBorder   = AppColors.surfaceElevated;
const _kBorder2  = Color(0xFF30363d);
const _kTextPri  = AppColors.textPrimary;
const _kTextSec  = AppColors.textSecondary;
const _kBlue     = AppColors.blue;
const _kPurple   = AppColors.purple;
const _kGold     = AppColors.orange;

// ── tabs ──────────────────────────────────────────────────────────────────────
const _kTabs = ['Overview', 'Equipment', 'Inventory', 'Achievements'];

// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  CharacterProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _kTabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadProfile();
  }

  Future<void> refresh() => _loadProfile();

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await CharacterService().getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Failed to load profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPri,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: _kTextSec),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _loadProfile,
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── profile header ────────────────────────────────────────────
          _ProfileHeader(tabController: _tab, profile: profile),

          // ── tab content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(profile: profile, onStatSpent: _loadProfile),
                const _PlaceholderTab('Equipment', '🛡️'),
                const _PlaceholderTab('Inventory', '🎒'),
                const _PlaceholderTab('Achievements', '🏆'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── profile header (avatar + identity + tab bar) ──────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final TabController tabController;
  final CharacterProfile profile;
  const _ProfileHeader({required this.tabController, required this.profile});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final rankAccent = _rankColor(profile.rank);
    final titleText =
        '${profile.classEmoji ?? ''} ${profile.className ?? 'Hero'}'.trim();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF080e14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x104f9eff), Color(0x00040810)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top + 12),

          // ── avatar row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_kBlue, _kPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kBlue.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      profile.avatarEmoji ?? '🧙',
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // identity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _kTextPri,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // class badge (title placeholder)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kGold.withOpacity(0.10),
                          border:
                              Border.all(color: _kGold.withOpacity(0.40)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // rank + level sub-text
                      Row(
                        children: [
                          _RankBadge(
                              rank: profile.rank, color: rankAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Level ${profile.level}',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextSec),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // settings icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder2),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      size: 18, color: _kTextSec),
                ),
              ],
            ),
          ),

          // ── tab bar ────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _kBlue,
              unselectedLabelColor: _kTextSec,
              labelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600),
              indicatorColor: _kBlue,
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              tabs: _kTabs.map((t) => Tab(text: t, height: 36)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── rank badge ────────────────────────────────────────────────────────────────
class _RankBadge extends StatelessWidget {
  final String rank;
  final Color color;
  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: Text(
        rank,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── overview tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final CharacterProfile profile;
  final VoidCallback onStatSpent;
  const _OverviewTab({required this.profile, required this.onStatSpent});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      children: [
        _XPSection(profile: profile),
        const SizedBox(height: 20),
        _StatsSection(
          stats: _buildStats(profile),
          availablePoints: profile.availableStatPoints,
          onStatSpent: onStatSpent,
        ),
        const SizedBox(height: 20),
        _ActivitySummary(profile: profile),
      ],
    );
  }
}

// ── XP bar section ────────────────────────────────────────────────────────────
class _XPSection extends StatelessWidget {
  final CharacterProfile profile;
  const _XPSection({required this.profile});

  static void _showXPHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _XPHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = profile.xpProgress;
    final remaining = profile.xpRemaining;

    return GestureDetector(
      onTap: () => _showXPHistory(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // level + xp label row
            Row(
              children: [
                // level circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _kBlue.withOpacity(0.25),
                        _kBlue.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                        color: _kBlue.withOpacity(0.5), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '${profile.level}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Level ${profile.level}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kTextPri,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '→ ${profile.level + 1}',
                            style: const TextStyle(
                                fontSize: 12, color: _kTextSec),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fmt(profile.xp)} / ${_fmt(profile.xpForNextLevel)} XP  ·  ${_fmt(remaining < 0 ? 0 : remaining)} to go',
                        style: const TextStyle(
                            fontSize: 10, color: _kTextSec),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kTextSec,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.history, size: 14, color: _kTextSec),
              ],
            ),

            const SizedBox(height: 12),

            // XP bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 8, color: _kSurface2),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kBlue, _kPurple],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ── XP history bottom sheet ───────────────────────────────────────────────────
class _XPHistorySheet extends StatefulWidget {
  const _XPHistorySheet();

  @override
  State<_XPHistorySheet> createState() => _XPHistorySheetState();
}

class _XPHistorySheetState extends State<_XPHistorySheet> {
  List<XpHistoryEntry>? _entries;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await CharacterService().getXpHistory();
      if (mounted) setState(() { _entries = entries; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalXp = _entries?.fold<int>(0, (sum, e) => sum + e.xp) ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: const Color(0xFF0f1828),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _kBlue.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2a3a5a),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBlue.withOpacity(0.4)),
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kTextPri),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Experience gained',
                      style: TextStyle(fontSize: 11, color: _kTextSec),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: _kBorder2, height: 1),

          // body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kBlue))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Failed to load history', style: TextStyle(color: _kTextPri, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
                              child: const Text('Retry', style: TextStyle(color: _kBlue)),
                            ),
                          ],
                        ),
                      )
                    : _entries!.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('⚡', style: TextStyle(fontSize: 40)),
                                SizedBox(height: 12),
                                Text('No XP earned yet', style: TextStyle(color: _kTextPri, fontSize: 14, fontWeight: FontWeight.w700)),
                                SizedBox(height: 4),
                                Text('Complete activities to earn XP', style: TextStyle(color: _kTextSec, fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                            itemCount: _entries!.length,
                            separatorBuilder: (_, __) => const Divider(color: _kBorder2, height: 1),
                            itemBuilder: (_, i) => _XPEntryRow(entry: _entries![i]),
                          ),
          ),

          // total footer
          if (!_loading && _error == null && _entries != null && _entries!.isNotEmpty) ...[
            const Divider(color: _kBorder2, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL XP EARNED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kTextSec, letterSpacing: 0.7),
                  ),
                  Text(
                    '+${totalXp >= 1000 ? '${(totalXp / 1000).toStringAsFixed(1)}k' : totalXp} XP',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kBlue),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── XP entry row ──────────────────────────────────────────────────────────────
class _XPEntryRow extends StatelessWidget {
  final XpHistoryEntry entry;
  const _XPEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBlue.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(entry.sourceEmoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.source, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextPri)),
                const SizedBox(height: 2),
                Text(entry.description, style: const TextStyle(fontSize: 11, color: _kTextSec)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${entry.xp} XP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kBlue)),
              const SizedBox(height: 2),
              Text(entry.timeAgo, style: const TextStyle(fontSize: 10, color: _kTextSec)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── core stats section ────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  final List<_StatData> stats;
  final int availablePoints;
  final VoidCallback onStatSpent;
  const _StatsSection({
    required this.stats,
    required this.availablePoints,
    required this.onStatSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availablePoints > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.blue.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    '$availablePoints stat point${availablePoints == 1 ? '' : 's'} available — tap + to spend',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'CORE STATS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kTextSec,
              letterSpacing: 0.7,
            ),
          ),
        ),
        for (final stat in stats) ...[
          _StatCard(
            stat: stat,
            availablePoints: availablePoints,
            onStatSpent: onStatSpent,
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final _StatData stat;
  final int availablePoints;
  final VoidCallback onStatSpent;
  const _StatCard({
    required this.stat,
    required this.availablePoints,
    required this.onStatSpent,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _spending = false;

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StatDetailSheet(
        stat: widget.stat,
        availablePoints: widget.availablePoints,
        onStatSpent: widget.onStatSpent,
      ),
    );
  }

  Future<void> _spendPoint() async {
    setState(() => _spending = true);
    try {
      await CharacterService().spendStatPoint(widget.stat.key);
      widget.onStatSpent();
    } catch (_) {
      // silently fail — profile will not refresh
    } finally {
      if (mounted) setState(() => _spending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.stat.value / 100.0).clamp(0.0, 1.0);
    final hasPoints = widget.availablePoints > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasPoints ? widget.stat.color.withOpacity(0.5) : _kBorder,
            ),
          ),
          child: Row(
            children: [
              // emoji icon
              SizedBox(
                width: 32,
                child: Text(widget.stat.emoji,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),

              // stat key
              SizedBox(
                width: 34,
                child: Text(widget.stat.key,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _kTextPri)),
              ),

              // bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(children: [
                    Container(height: 5, color: _kSurface2),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: widget.stat.color,
                          boxShadow: [
                            BoxShadow(
                              color: widget.stat.color.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(width: 10),

              // value
              SizedBox(
                width: 28,
                child: Text('${widget.stat.value}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.stat.color)),
              ),

              // + button — only when points available
              if (hasPoints) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _spending ? null : _spendPoint,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: widget.stat.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.stat.color.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: widget.stat.color.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: _spending
                        ? Padding(
                            padding: const EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: widget.stat.color),
                          )
                        : Icon(Icons.add, size: 16, color: widget.stat.color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── stat detail bottom sheet ──────────────────────────────────────────────────
class _StatDetailSheet extends StatefulWidget {
  final _StatData stat;
  final int availablePoints;
  final VoidCallback onStatSpent;
  const _StatDetailSheet({
    required this.stat,
    required this.availablePoints,
    required this.onStatSpent,
  });

  @override
  State<_StatDetailSheet> createState() => _StatDetailSheetState();
}

class _StatDetailSheetState extends State<_StatDetailSheet> {
  bool _spending = false;

  Future<void> _spendPoint() async {
    setState(() => _spending = true);
    try {
      await CharacterService().spendStatPoint(widget.stat.key);
      widget.onStatSpent();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _spending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.stat.value / 100.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(top: 120),
      decoration: BoxDecoration(
        color: const Color(0xFF0f1828),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: widget.stat.color.withOpacity(0.25)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2a3a5a),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // header row
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.stat.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: widget.stat.color.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      widget.stat.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stat.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kTextPri,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.stat.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.stat.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // value badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.stat.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: widget.stat.color.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${widget.stat.value}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.stat.color,
                    ),
                  ),
                ),
                // + button — only when points available
                if (widget.availablePoints > 0) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _spending ? null : _spendPoint,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.stat.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: widget.stat.color.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: widget.stat.color.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: _spending
                          ? Padding(
                              padding: const EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: widget.stat.color),
                            )
                          : Icon(Icons.add,
                              size: 18, color: widget.stat.color),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 8, color: _kSurface2),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.stat.color,
                        boxShadow: [
                          BoxShadow(
                            color: widget.stat.color.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: ${widget.stat.value} / 100',
                  style: const TextStyle(fontSize: 10, color: _kTextSec),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: widget.stat.color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // description
            Text(
              widget.stat.description,
              style: const TextStyle(
                  fontSize: 13, color: _kTextPri, height: 1.55),
            ),

            const SizedBox(height: 20),

            // raised by
            _SheetSection(
              label: 'RAISED BY',
              color: widget.stat.color,
              items: widget.stat.activities,
            ),

            const SizedBox(height: 16),

            // perks
            _SheetSection(
              label: 'HIGH ${widget.stat.key} PERKS',
              color: widget.stat.color,
              items: widget.stat.perks,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> items;
  const _SheetSection({
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 5, right: 10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                      fontSize: 12, color: _kTextPri, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

// ── activity summary (mini cards row) ─────────────────────────────────────────
class _ActivitySummary extends StatelessWidget {
  final CharacterProfile profile;
  const _ActivitySummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            'THIS WEEK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kTextSec,
              letterSpacing: 0.7,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _MiniCard(
                emoji: '🏃',
                label: 'Runs',
                value: '${profile.weeklyRuns}',
                sub: 'this week',
              ),
              const SizedBox(width: 10),
              _MiniCard(
                emoji: '📏',
                label: 'Distance',
                value: '${profile.weeklyDistanceKm.toStringAsFixed(1)} km',
                sub: 'total',
              ),
              const SizedBox(width: 10),
              _MiniCard(
                emoji: '🔥',
                label: 'Streak',
                value: '${profile.currentStreak} days',
                sub: 'current',
              ),
              const SizedBox(width: 10),
              _MiniCard(
                emoji: '⚡',
                label: 'XP Earned',
                value: _fmt(profile.weeklyXpEarned),
                sub: 'this week',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;
  const _MiniCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _kTextSec,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kTextPri,
            ),
          ),
          Text(sub, style: const TextStyle(fontSize: 9, color: _kTextSec)),
        ],
      ),
    );
  }
}

// ── placeholder for unimplemented tabs ────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final String label;
  final String emoji;
  const _PlaceholderTab(this.label, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextPri,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coming soon',
            style: TextStyle(fontSize: 12, color: _kTextSec),
          ),
        ],
      ),
    );
  }
}
