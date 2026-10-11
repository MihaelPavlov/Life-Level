import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../activity/log_activity_screen.dart';
import '../models/boss_list_item.dart';
import '../providers/boss_provider.dart';
import '../widgets/boss_damage_hit_row.dart';
import '../widgets/boss_hit_fx.dart';
import '../widgets/boss_duel_arena.dart';
import '../widgets/boss_hp_bar.dart';
import '../../items/providers/items_provider.dart';
import '../../map/widgets/world_map_theme.dart';
import '../models/boss_damage_history.dart';
import '../replay/boss_replay.dart';

/// Inline battle view displayed within BossScreen (keeps bottom nav visible).
class BossBattleView extends ConsumerStatefulWidget {
  final BossListItem boss;
  final VoidCallback onBack;
  final VoidCallback? onRefreshRequested;

  const BossBattleView({
    super.key,
    required this.boss,
    required this.onBack,
    this.onRefreshRequested,
  });

  @override
  ConsumerState<BossBattleView> createState() => _BossBattleViewState();
}

class _BossBattleViewState extends ConsumerState<BossBattleView>
    with SingleTickerProviderStateMixin {
  BossListItem get boss => widget.boss;
  VoidCallback get onBack => widget.onBack;

  // ── Hit animation ("slash + ember burn") ──
  // Plays when hpDealt rises while the battle is on screen: a slash across
  // the avatar, a short screen shake, a floating damage number, the HP
  // number counting down and the lost HP burning away as an orange ember.
  static const _hitMs = 1300.0;
  final _avatarKey = GlobalKey();
  final _heroKey = GlobalKey();

  /// Bumped to make the duel arena play one exchange (hit + counter).
  int _exchange = 0;
  int? _counterDamage;
  int? _counterBlocked;
  bool _counter = true;

  /// The top bar floats over the arena's scene; it gains a solid backdrop
  /// once the page scrolls.
  static const double _topBarH = 44;
  final _scroll = ScrollController();
  double _barShade = 0;
  late final AnimationController _hit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..addListener(() => setState(() {}));
  int _dealtFrom = 0;
  int _dealtTo = 0;

  double get _hitMsNow => _hit.value * _hitMs;
  bool get _hitting => _hit.isAnimating;

  double _phase(double start, double len, [Curve curve = Curves.linear]) =>
      curve.transform(((_hitMsNow - start) / len).clamp(0.0, 1.0));

  /// Damage dealt as currently displayed (counts up during a hit).
  int get _shownDealt => _hitting
      ? (_dealtFrom +
              (_dealtTo - _dealtFrom) * _phase(120, 700, Curves.easeOutCubic))
          .round()
      : boss.hpDealt;

  double get _shakeDx {
    if (!_hitting) return 0;
    final p = _phase(120, 380);
    if (p <= 0 || p >= 1) return 0;
    return math.sin(p * math.pi * 6) * 6 * (1 - p);
  }

  void _playHit(int from, int to) {
    if (!RewardFx.enabled(context)) return;
    _dealtFrom = from;
    _dealtTo = to;
    _hit.forward(from: 0);
    AppMotion.haptic(AppHaptic.light);
    // The newest hit's counter-attack, when history already has it.
    final latest = ref.read(bossDamageHistoryProvider(boss.id)).valueOrNull;
    final hit = latest != null && latest.isNotEmpty ? latest.first : null;
    setState(() {
      _exchange++;
      _counterDamage =
          hit != null && hit.damage == to - from ? hit.damageTaken : null;
      _counterBlocked =
          hit != null && hit.damage == to - from ? hit.damageBlocked : null;
      // Only skip his answer when the matching hit says he didn't make one.
      _counter = hit == null ||
          hit.damage != to - from ||
          (hit.skipReason == null && !hit.bossDefeated);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = RewardFx.centerOf(_avatarKey);
      if (c == null) return;
      BossSlash.play(context, c);
      RewardFx.burst(context, c, AppColors.red,
          count: 12, distance: 60, delay: const Duration(milliseconds: 120));
      RewardFx.floatText(
        context,
        c + const Offset(30, -80),
        '−${_fmtNumber(to - from)}',
        AppColors.orange,
        fontSize: 26,
        rise: 28,
        popScale: 1.2,
        duration: const Duration(milliseconds: 1300),
        delay: const Duration(milliseconds: 120),
      );
    });
  }

  /// Exchanges logged since you last watched this boss (e.g. a Strava sync
  /// while the app was closed) play here in the arena, one real turn at a
  /// time, then are marked seen so Home and the boss list don't replay them.
  /// Same finder and cursor as the boss list's replay.
  bool _replayChecked = false;

  Future<void> _maybeReplayUnseen() async {
    if (_replayChecked) return;
    _replayChecked = true;
    BossReplay? replay;
    try {
      replay = await BossReplayFinder.find(ref.read(bossPageServiceProvider),
          onlyBossId: boss.id);
    } catch (_) {}
    if (replay == null || !mounted) return;
    final motion = RewardFx.enabled(context);
    if (motion) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      for (final t in replay.playable) {
        if (!mounted) return;
        _playTurn(t);
        if (t.finisher) break;
        await Future<void>.delayed(const Duration(milliseconds: 2100));
      }
    }
    if (!mounted) return;
    await BossReplayFinder.markSeen(replay);
  }

  /// One real turn in the arena: your hit on the boss, then his answer
  /// unless you were recovering or the hit finished him.
  void _playTurn(BossReplayTurn t) {
    setState(() {
      _exchange++;
      _counterDamage = t.taken;
      _counterBlocked = t.blocked;
      _counter = !t.recovering && !t.finisher;
    });
    AppMotion.haptic(AppHaptic.light);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = RewardFx.centerOf(_avatarKey);
      if (c == null) return;
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (!mounted) return;
        BossSlash.play(context, c);
        RewardFx.burst(context, c, AppColors.red, count: 12, distance: 60);
        RewardFx.floatText(context, c + const Offset(30, -80),
            '−${_fmtNumber(t.dealt)}', AppColors.orange,
            fontSize: 26,
            rise: 28,
            popScale: 1.2,
            duration: const Duration(milliseconds: 1300));
        if (t.recovering) {
          RewardFx.floatText(context, c + const Offset(0, 90),
              'Recovering · no attack', AppColors.textSecondary,
              pill: true, fontSize: 11);
        }
      });
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _hit.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // The battle view plays its own hit; record the HP shown here so the
    // home / map cards don't replay the same drop later.
    BossHitMemory.markSeen(boss.id, boss.hpRemaining);
    _scroll.addListener(() {
      final shade = (_scroll.offset / 60).clamp(0.0, 1.0);
      if (shade != _barShade) setState(() => _barShade = shade);
    });
    Future.microtask(_refreshBattleData);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeReplayUnseen());
  }

  @override
  void didUpdateWidget(covariant BossBattleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    BossHitMemory.markSeen(widget.boss.id, widget.boss.hpRemaining);
    if (oldWidget.boss.id != widget.boss.id ||
        oldWidget.boss.hpDealt != widget.boss.hpDealt) {
      Future.microtask(_refreshBattleData);
    }
    if (oldWidget.boss.id == widget.boss.id &&
        widget.boss.hpDealt > oldWidget.boss.hpDealt) {
      _playHit(oldWidget.boss.hpDealt, widget.boss.hpDealt);
    }
  }

  void _refreshBattleData() {
    ref.invalidate(bossDamageHistoryProvider(boss.id));
    widget.onRefreshRequested?.call();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = boss.timeRemaining;
    // World-zone bosses suppress the legacy 7-day expiry — backend returns
    // `timerExpiresAt: null` and `timerDays: 0`. Render ∞ / "no limit"
    // instead of the misleading "0d left" that the legacy formula prints.
    final timerText = remaining != null
        ? '${_fmtDuration(remaining)} left'
        : (boss.timerDays > 0 ? '${boss.timerDays}d left' : '∞ no limit');

    return Material(
      color: const Color(0xFF060b10),
      child: Stack(
        children: [
          // ── Background glow ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 0.8,
                  colors: [
                    AppColors.red.withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          Positioned.fill(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.only(
                  bottom: 40 + MediaQuery.paddingOf(context).bottom),
              children: [
                Transform.translate(
                  offset: Offset(_shakeDx, 0),
                  child: Column(children: [
                    _buildHero(),
                    const SizedBox(height: 16),
                    _buildHpSection(),
                  ]),
                ),
                const SizedBox(height: 12),
                _buildPlayerSection(),
                const SizedBox(height: 12),
                _buildMyDamage(),
                const SizedBox(height: 16),
                _buildRecentHits(ref),
                const SizedBox(height: 16),
                _buildCtas(context),
              ],
            ),
          ),

          // ── Top bar, floating over the arena's scene ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ColoredBox(
              color: const Color(0xFF060b10).withValues(alpha: .94 * _barShade),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: _topBarH,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onBack,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: Text(
                              '\u2190 Bosses',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.1),
                            border: Border.all(
                                color: AppColors.red.withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '⏱ $timerText',
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final equipment = ref.watch(equipmentProvider).valueOrNull;
    final background = RegionArtwork.backgroundFor(boss.region) ??
        RegionArtwork.backgroundFor(boss.regionDisplay);
    // The scene runs from the very top of the screen (behind the floating
    // top bar and the tag) down past the fight, fading out under the name.
    final barBottom = MediaQuery.paddingOf(context).top + _topBarH;
    const tagH = 34.0;
    const nameH = 64.0;
    return Stack(
      children: [
        // Your hero vs the boss (design: Boss Screen Redesign canvas, "C2").
        BossDuelArena(
          bossName: boss.name,
          bossIcon: boss.icon,
          backgroundAsset: background,
          equipment: equipment,
          bossKey: _avatarKey,
          heroKey: _heroKey,
          exchange: _exchange,
          counterDamage: _counterDamage,
          counterBlocked: _counterBlocked,
          counter: _counter,
          topInset: barBottom + tagH,
          bottomExtend: nameH,
        ),
        // Tag
        Positioned(
          top: barBottom + 6,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF060b10).withValues(alpha: 0.55),
                border:
                    Border.all(color: AppColors.red.withValues(alpha: 0.45)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                [
                  boss.isMini ? '\u26A1 MINI BOSS' : '\u26A0\uFE0F ELITE BOSS',
                  if (boss.regionDisplay.trim().isNotEmpty)
                    boss.regionDisplay.toUpperCase(),
                ].join(' \u00B7 '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
        ),
        // Name, in the scene's fade.
        Positioned(
          left: 20,
          right: 20,
          bottom: 8,
          child: Column(
            children: [
              Text(
                boss.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Defeat by burning calories',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHpSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BOSS HP',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${_fmtNumber(boss.maxHp - _shownDealt)} / ${_fmtNumber(boss.maxHp)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          BossHpBar(
              hpDealt: _hitting && _hitMsNow < 120 ? _dealtFrom : boss.hpDealt,
              maxHp: boss.maxHp,
              showLabel: false,
              height: 14,
              emberHpDealt: _hitting
                  ? (_dealtFrom +
                          (_dealtTo - _dealtFrom) *
                              _phase(320, 900, const Cubic(.5, 0, .6, 1)))
                      .round()
                  : null),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${((boss.maxHp - _shownDealt) / boss.maxHp * 100).toStringAsFixed(0)}% remaining',
              style: const TextStyle(color: Color(0xFF586070), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDamage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY TOTAL DAMAGE',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'From all your workouts this battle',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _fmtNumber(_shownDealt),
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection() {
    final maxHp = boss.playerMaxHp <= 0 ? 1 : boss.playerMaxHp;
    final hp = boss.currentPlayerHp.clamp(0, maxHp);
    final recovery = boss.recoveryEndsAt?.difference(DateTime.now().toUtc());
    final recovering = recovery != null && !recovery.isNegative;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (recovering ? AppColors.orange : AppColors.blue)
            .withValues(alpha: 0.07),
        border: Border.all(
          color: (recovering ? AppColors.orange : AppColors.blue)
              .withValues(alpha: 0.28),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                recovering ? '❤️ RECOVERING' : '❤️ YOUR HP',
                style: TextStyle(
                  color: recovering ? AppColors.orange : AppColors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
              const Spacer(),
              Text('$hp / $maxHp',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: hp / maxHp,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
                recovering ? AppColors.orange : AppColors.blue),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                    'DEF ${boss.playerDefense} · ${(boss.playerMitigation * 100).toStringAsFixed(0)}% mitigation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                    'Boss armor ${boss.armor} · ATK ${boss.counterattackDamage}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ),
            ],
          ),
          if (recovering) ...[
            const SizedBox(height: 8),
            Text(
              'Workout attacks resume in ${_fmtDuration(recovery)}. Normal workout rewards still apply.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.orange, fontSize: 11, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentHits(WidgetRef ref) {
    final historyAsync = ref.watch(bossDamageHistoryProvider(boss.id));
    final hits = historyAsync.valueOrNull ?? const <BossDamageHistoryItem>[];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 0),
            child: Row(
              children: [
                const Text(
                  'RECENT HITS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                if (hits.isNotEmpty)
                  TextButton(
                    onPressed: () => _showHistorySheet(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A84),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('See all',
                            style: TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                        Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 40),
              ],
            ),
          ),
          historyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
                  ),
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                children: [
                  const Text(
                    'Couldn\'t load damage history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(bossDamageHistoryProvider(boss.id)),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            data: (hits) {
              if (hits.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 2, 16, 16),
                  child: Column(
                    children: [
                      Text(
                        'Damage is dealt automatically when you log workouts or sync activities from Strava.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Log a workout to deal damage!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final hit in hits.take(3)) BossDamageHitRow(hit: hit),
                ],
              );
            },
          ),
          if (hits.isNotEmpty)
            InkWell(
              onTap: () => _showHistorySheet(context),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Full damage history · ${hits.length} ${hits.length == 1 ? 'hit' : 'hits'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCtas(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: [AppColors.green, Color(0xFF2d8f3c)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => _openLogWorkout(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                '\u26A1 Log Workout',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  static String _fmtNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }

  Future<void> _openLogWorkout(BuildContext context) async {
    await Navigator.of(context).push(
      AppRoute<void>(
        builder: (_) => const LogActivityScreen(),
      ),
    );
    if (!mounted) return;
    _refreshBattleData();
  }

  void _showHistorySheet(BuildContext context) {
    _refreshBattleData();
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BossDamageHistorySheet(
        bossId: boss.id,
        bossName: boss.name,
        maxHp: boss.maxHp,
        hpRemaining: boss.maxHp - boss.hpDealt,
      ),
    );
  }
}

/// "See all": every hit of this battle (design: Boss Screen Redesign canvas,
/// "C2 · full damage history"). A summary of the battle, the boss's HP
/// strip, then the hits grouped by day; tap one to see its maths.
class _BossDamageHistorySheet extends ConsumerStatefulWidget {
  final String bossId;
  final String bossName;
  final int maxHp;
  final int hpRemaining;

  const _BossDamageHistorySheet({
    required this.bossId,
    required this.bossName,
    required this.maxHp,
    required this.hpRemaining,
  });

  @override
  ConsumerState<_BossDamageHistorySheet> createState() =>
      _BossDamageHistorySheetState();
}

class _BossDamageHistorySheetState
    extends ConsumerState<_BossDamageHistorySheet> {
  /// The hit whose maths is open; the newest one by default.
  String? _openId;
  bool _openPicked = false;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(bossDamageHistoryProvider(widget.bossId));
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    final hits = historyAsync.valueOrNull ?? const <BossDamageHistoryItem>[];
    if (!_openPicked && hits.isNotEmpty) {
      _openId = hits.where((h) => h.skipReason == null).firstOrNull?.activityId;
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF0d1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Damage history',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hits.isEmpty
                              ? widget.bossName
                              : '${widget.bossName} · ${hits.length} ${hits.length == 1 ? 'workout' : 'workouts'} this battle',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (hits.isNotEmpty) _summary(hits),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: historyAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.red),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Couldn\'t load damage history.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(
                              bossDamageHistoryProvider(widget.bossId)),
                          child: const Text('Retry',
                              style: TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (hits) {
                  if (hits.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'No workout hits yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }
                  final rows = <Widget>[];
                  String? lastDay;
                  for (final hit in hits) {
                    final day = _dayLabel(hit.loggedAt);
                    if (day != lastDay) {
                      lastDay = day;
                      rows.add(Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                        child: Text(
                          day,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ));
                    }
                    final open = _openId == hit.activityId;
                    rows.add(BossDamageHitRow(
                      hit: hit,
                      expanded: open,
                      onTap: () => setState(() {
                        _openPicked = true;
                        _openId = open ? null : hit.activityId;
                      }),
                    ));
                  }
                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
                    children: rows,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(List<BossDamageHistoryItem> hits) {
    var dealt = 0, taken = 0, blocked = 0;
    for (final h in hits) {
      if (h.skipReason != null) continue;
      dealt += h.damage;
      taken += h.damageTaken;
      blocked += h.damageBlocked;
    }
    Widget tile(String label, int value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              border: Border.all(color: color.withValues(alpha: .3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8)),
                const SizedBox(height: 3),
                Text(_thousands(value),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        );
    final left = widget.maxHp <= 0
        ? 0.0
        : (widget.hpRemaining / widget.maxHp).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              tile('YOU DEALT', dealt, AppColors.red),
              const SizedBox(width: 8),
              tile('YOU TOOK', taken, AppColors.blue),
              const SizedBox(width: 8),
              tile('BLOCKED', blocked, AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Boss HP',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const Spacer(),
              Text(
                '${_thousands(widget.maxHp)} → ${_thousands(widget.hpRemaining)}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (left * 1000).round(),
                    child: const ColoredBox(color: AppColors.red),
                  ),
                  Expanded(
                    flex: 1000 - (left * 1000).round(),
                    child:
                        ColoredBox(color: AppColors.red.withValues(alpha: .22)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _dayLabel(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return 'EARLIER';
  }

  static String _thousands(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return n < 0 ? '-$b' : b.toString();
  }
}
