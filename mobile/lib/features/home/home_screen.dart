import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/level_up_notifier.dart';
import '../../core/widgets/level_up_overlay.dart';
import '../character/character_service.dart';
import '../character/models/character_profile.dart';

// ─── local palette constants (keep in sync with AppColors) ───────────────────
const _bgBase      = Color(0xFF080e14);
const _surface1    = Color(0xFF161b22);
const _surface2    = Color(0xFF1e2632);
const _borderColor = Color(0xFF30363d);
const _borderSoft  = Color(0xFF1e2632);
const _textMuted   = Color(0xFF4d5b6b);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  CharacterProfile? _profile;

  final _characterService = CharacterService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Called by MainShell when the home tab is selected.
  Future<void> refresh() async {
    final oldLevel = _profile?.level;
    await _loadProfile();
    if (mounted && _profile != null && oldLevel != null && _profile!.level > oldLevel) {
      LevelUpNotifier.notify(_profile!.level);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _characterService.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── main build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: _bgBase,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildXpCard(),
                      _buildStreakCard(),
                      _buildQuestsCard(),
                      _buildLastActivityCard(),
                      _buildStatsRow(),
                      _buildBossCard(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left: greeting + name + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning 👋',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  _profile?.username ?? '...',
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  children: [
                    _badge('LV ${_profile?.level ?? '?'}', AppColors.blue),
                    if (_profile != null) _badge(_profile!.rank.toUpperCase(), AppColors.purple),
                    if (_profile?.className != null) _badge(_profile!.className!.toUpperCase(), AppColors.orange),
                  ],
                ),
              ],
            ),
          ),
          // right: avatar + tappable LV badge + notification dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              // avatar circle
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.blue, AppColors.purple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.35),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(_profile?.avatarEmoji ?? '🏃', style: const TextStyle(fontSize: 24)),
                ),
              ),
              // tappable LV badge — pulsing hint
              Positioned(
                bottom: -4,
                left: 0, right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => showLevelUpScreen(context, _profile?.level ?? 1),
                    child: _PulsingLvBadge(label: 'LV ${_profile?.level ?? '?'}'),
                  ),
                ),
              ),
              // notification dot
              Positioned(
                top: -2, right: -2,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bgBase, width: 2),
                  ),
                  child: const Center(
                    child: Text('3',
                        style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── XP PROGRESS CARD ────────────────────────────────────────────────────────
  Widget _buildXpCard() {
    final p = _profile;
    final progress = p?.xpProgress ?? 0.0;
    final pct = '${(progress * 100).round()}%';
    return _Card(
      borderColor: AppColors.blue.withValues(alpha: 0.28),
      glowColor: AppColors.blue.withValues(alpha: 0.07),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p != null ? 'Level ${p.level}' : '...',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(p != null ? '${_fmt(p.xp)} / ${_fmt(p.xpForNextLevel)} XP' : '...',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text(p != null ? 'Level ${p.level + 1}' : '...',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          _ProgressBar(progress: progress, colors: [AppColors.blue, AppColors.purple], height: 10),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p != null ? '${_fmt(p.xpRemaining)} XP to next level' : '...',
                  style: const TextStyle(fontSize: 10, color: _textMuted)),
              Text(pct,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  // ── STREAK CARD ─────────────────────────────────────────────────────────────
  Widget _buildStreakCard() {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('14-Day Streak',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Reward in 7 days — ×1.5 XP bonus',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _badge('🛡 Shield ready', AppColors.green, fontSize: 9),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StreakDay(icon: '✓',  label: 'MON',   state: _StreakState.done),
              const SizedBox(width: 5),
              _StreakDay(icon: '✓',  label: 'TUE',   state: _StreakState.done),
              const SizedBox(width: 5),
              _StreakDay(icon: '✓',  label: 'WED',   state: _StreakState.done),
              const SizedBox(width: 5),
              _StreakDay(icon: '✓',  label: 'THU',   state: _StreakState.done),
              const SizedBox(width: 5),
              _StreakDay(icon: '✓',  label: 'FRI',   state: _StreakState.done),
              const SizedBox(width: 5),
              _StreakDay(icon: '✓',  label: 'SAT',   state: _StreakState.done),
              const SizedBox(width: 5),
              _StreakDay(icon: '🔥', label: 'TODAY', state: _StreakState.today),
            ],
          ),
        ],
      ),
    );
  }

  // ── DAILY QUESTS CARD ───────────────────────────────────────────────────────
  Widget _buildQuestsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(label: 'DAILY QUESTS', action: '3 / 5 done · resets 12h'),
          _QuestItem(
            icon: '🏃', iconState: _QuestState.done,
            name: 'Run 30 minutes', sub: '32 min completed',
            xp: '+150 XP', done: true,
          ),
          _QuestItem(
            icon: '🔥', iconState: _QuestState.done,
            name: 'Burn 300 calories', sub: '348 cal burned',
            xp: '+100 XP', done: true,
          ),
          _QuestItem(
            icon: '📍', iconState: _QuestState.done,
            name: 'Cover 5 km', sub: '5.2 km logged',
            xp: '+100 XP', done: true,
          ),
          _QuestItem(
            icon: '💪', iconState: _QuestState.active,
            name: 'Strength session', sub: '0 / 1 session',
            xp: '+150 XP', done: false, progress: 0.0,
            progressColor: AppColors.red,
          ),
          _QuestItem(
            icon: '🧘', iconState: _QuestState.active,
            name: '10 min yoga / stretch', sub: '0 / 10 minutes',
            xp: '+100 XP', done: false, progress: 0.0,
            progressColor: AppColors.purple,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.06),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Complete all 5 quests',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('+300 Bonus XP',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LAST ACTIVITY CARD ──────────────────────────────────────────────────────
  Widget _buildLastActivityCard() {
    return _Card(
      borderColor: AppColors.green.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(label: 'LAST ACTIVITY', action: '2 hours ago'),
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(child: Text('🏃', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Morning Run',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('5.2 km · 28:14 · Avg 5:26/km · 156 bpm',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _GainChip(label: '+450 XP', color: AppColors.orange),
                        _GainChip(label: '+2 END',  color: AppColors.green),
                        _GainChip(label: '+2 AGI',  color: AppColors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CHARACTER STATS ROW ─────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(label: 'CHARACTER STATS'),
          Row(
            children: [
              _StatGem(value: '84', label: 'STR', color: AppColors.red),
              const SizedBox(width: 6),
              _StatGem(value: '71', label: 'END', color: AppColors.green),
              const SizedBox(width: 6),
              _StatGem(value: '92', label: 'AGI', color: AppColors.blue),
              const SizedBox(width: 6),
              _StatGem(value: '65', label: 'FLX', color: AppColors.purple),
              const SizedBox(width: 6),
              _StatGem(value: '78', label: 'STA', color: AppColors.orange),
            ],
          ),
        ],
      ),
    );
  }

  // ── BOSS CARD ───────────────────────────────────────────────────────────────
  Widget _buildBossCard() {
    return _Card(
      borderColor: AppColors.red.withValues(alpha: 0.28),
      glowColor: AppColors.red.withValues(alpha: 0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            label: 'ACTIVE BOSS',
            action: 'Fight now →',
            actionColor: AppColors.red,
          ),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🗻', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Iron Peak Mountain',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('⏰ 4d 12h remaining',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red)),
                  const SizedBox(height: 1),
                  Text('HP: 8,420 / 12,000 · Veteran difficulty',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('8,420 HP remaining',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              Text('70%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red)),
            ],
          ),
          const SizedBox(height: 4),
          _ProgressBar(progress: 0.70, colors: [AppColors.red, const Color(0xFFc0392b)]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              _badge('🗡 You dealt 1,240 dmg', AppColors.red, fontSize: 9),
              _badge('+180 dmg / session', AppColors.orange, fontSize: 9),
            ],
          ),
        ],
      ),
    );
  }

  // ── shared badge widget ──────────────────────────────────────────────────────
  Widget _badge(String label, Color color, {double fontSize = 9}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

// ── Card container ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? glowColor;

  const _Card({required this.child, this.borderColor, this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface1,
        border: Border.all(color: borderColor ?? _borderColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor!, blurRadius: 24, spreadRadius: 0)]
            : null,
      ),
      child: child,
    );
  }
}

// ── Section title row ──────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String label;
  final String? action;
  final Color? actionColor;

  const _SectionTitle({required this.label, this.action, this.actionColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary, letterSpacing: 1.2,
              )),
          if (action != null)
            Text(action!,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: actionColor ?? AppColors.blue,
                )),
        ],
      ),
    );
  }
}

// ── Progress bar ───────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  final double height;

  const _ProgressBar({required this.progress, required this.colors, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: _surface2,
          valueColor: AlwaysStoppedAnimation<Color>(colors.first),
        ),
      ),
    );
  }
}

// ── Streak day dot ─────────────────────────────────────────────────────────────
enum _StreakState { done, today, next }

class _StreakDay extends StatelessWidget {
  final String icon;
  final String label;
  final _StreakState state;

  const _StreakDay({required this.icon, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final Color bg, border, textColor;
    switch (state) {
      case _StreakState.done:
        bg = AppColors.green.withValues(alpha: 0.1);
        border = AppColors.green.withValues(alpha: 0.3);
        textColor = AppColors.green;
      case _StreakState.today:
        bg = AppColors.orange.withValues(alpha: 0.12);
        border = AppColors.orange.withValues(alpha: 0.5);
        textColor = AppColors.orange;
      case _StreakState.next:
        bg = _surface2;
        border = _borderColor;
        textColor = _textMuted;
    }
    return Expanded(
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12, height: 1)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: textColor)),
          ],
        ),
      ),
    );
  }
}

// ── Quest item ─────────────────────────────────────────────────────────────────
enum _QuestState { done, active, pending }

class _QuestItem extends StatelessWidget {
  final String icon;
  final _QuestState iconState;
  final String name;
  final String sub;
  final String xp;
  final bool done;
  final double? progress;
  final Color? progressColor;

  const _QuestItem({
    required this.icon,
    required this.iconState,
    required this.name,
    required this.sub,
    required this.xp,
    required this.done,
    this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconBg, iconBorder;
    switch (iconState) {
      case _QuestState.done:
        iconBg = AppColors.green.withValues(alpha: 0.1);
        iconBorder = AppColors.green.withValues(alpha: 0.3);
      case _QuestState.active:
        iconBg = AppColors.blue.withValues(alpha: 0.08);
        iconBorder = AppColors.blue.withValues(alpha: 0.25);
      case _QuestState.pending:
        iconBg = AppColors.textSecondary.withValues(alpha: 0.06);
        iconBorder = AppColors.textSecondary.withValues(alpha: 0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              border: Border.all(color: iconBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 4),
                  _ProgressBar(
                    progress: progress!,
                    colors: [progressColor ?? AppColors.blue],
                    height: 4,
                  ),
                ],
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (done)
                Text('✓', style: TextStyle(fontSize: 16, color: AppColors.green, height: 1)),
              Text(xp, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Gain chip ──────────────────────────────────────────────────────────────────
class _GainChip extends StatelessWidget {
  final String label;
  final Color color;

  const _GainChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _surface2,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Stat gem ───────────────────────────────────────────────────────────────────
class _StatGem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatGem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: _surface1,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 1.0,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing LV badge (on avatar) ───────────────────────────────────────────────
class _PulsingLvBadge extends StatefulWidget {
  final String label;
  const _PulsingLvBadge({required this.label});

  @override
  State<_PulsingLvBadge> createState() => _PulsingLvBadgeState();
}

class _PulsingLvBadgeState extends State<_PulsingLvBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        final t = _glow.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _bgBase, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.25 + t * 0.25),
                blurRadius: 5 + t * 10,
                spreadRadius: 1 + t * 2,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
