import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../leaderboard/widgets/leaderboard_widgets.dart';
import '../../map/journey/journey_state.dart' show playerHpColor;
import '../models/boss_list_item.dart';
import 'boss_icon.dart';
import 'boss_hp_bar.dart';
import '../../unlocks/tour/tour_target.dart';
import '../../unlocks/tour/tours/unlock_tours.dart';

class BossActiveCard extends StatelessWidget {
  final BossListItem boss;
  final VoidCallback? onEnterBattle;

  /// The first active card carries the Bosses tour's targets.
  final bool tourTargets;

  /// While the page replays exchanges: the HP values on screen (null = live).
  final int? shownBossHp;
  final int? shownYouHp;

  /// The boss HP the orange ember still covers during a hit.
  final int? emberBossHp;
  final GlobalKey? portraitKey;
  final GlobalKey? avatarKey;
  final String? avatarEmoji;

  /// Badge in the corner during a combo ("×2 COMBO").
  final String? badge;

  const BossActiveCard({
    super.key,
    required this.boss,
    this.onEnterBattle,
    this.tourTargets = false,
    this.shownBossHp,
    this.shownYouHp,
    this.emberBossHp,
    this.portraitKey,
    this.avatarKey,
    this.avatarEmoji,
    this.badge,
  });

  Widget _target(String id, Widget child) =>
      tourTargets ? TourTarget(id: id, child: child) : child;

  bool get _canFight => onEnterBattle != null;

  @override
  Widget build(BuildContext context) {
    final remaining = boss.timeRemaining;
    // World-zone bosses suppress the legacy 7-day expiry — backend returns
    // `timerExpiresAt: null` and `timerDays: 0`. Surface that as "no limit"
    // instead of the misleading "0d remaining" the legacy formula prints.
    final hasTimer = boss.hasTimeLimit;
    final timerText = remaining != null
        ? _fmtDuration(remaining)
        : (boss.timerDays > 0 ? '${boss.timerDays}d' : '∞');
    final timerLabel = hasTimer ? 'remaining' : 'no limit';

    return GestureDetector(
      onTap: _canFight ? onEnterBattle : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.red.withValues(alpha: 0.5), width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF230808), Color(0xFF120606)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Column(
            children: [
              // ── Top row: avatar + info + timer ──
              _target(
                TourIds.bossTop,
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Row(
                    children: [
                      // Boss avatar
                      Container(
                        key: portraitKey,
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF280808),
                          border: Border.all(color: AppColors.red, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.red.withValues(alpha: 0.4),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: BossIcon(
                          icon: boss.displayIcon,
                          size: 76,
                          emojiSize: 42,
                          visualScale: 1.15,
                          visualOffset: const Offset(-0.75, -1.5),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boss.isMini
                                  ? '\u26A1 MINI BOSS'
                                  : '\u26A0\uFE0F ELITE BOSS',
                              style: TextStyle(
                                color: AppColors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              boss.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (boss.metadataLabel.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                boss.metadataLabel,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.1),
                          border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.35)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              timerText,
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timerLabel,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Body: HP + damage + CTA ──
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  children: [
                    _target(
                        TourIds.bossHp,
                        Column(children: [
                          BossHpBar(
                            hpDealt: shownBossHp == null
                                ? boss.hpDealt
                                : boss.maxHp - shownBossHp!,
                            maxHp: boss.maxHp,
                            emberHpDealt: emberBossHp == null
                                ? null
                                : boss.maxHp - emberBossHp!,
                          ),
                          if (boss.playerMaxHp > 0) ...[
                            const SizedBox(height: 14),
                            _youRow(),
                            const SizedBox(height: 8),
                            _statsLine(),
                          ],
                          const SizedBox(height: 14),
                          // My damage
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.07),
                              border: Border.all(
                                  color:
                                      AppColors.green.withValues(alpha: 0.25)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'MY DAMAGE DEALT',
                                  style: TextStyle(
                                    color: AppColors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  _fmtNumber(boss.hpDealt),
                                  style: const TextStyle(
                                    color: AppColors.red,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ])),
                    const SizedBox(height: 12),
                    // CTA or zone warning
                    if (_canFight)
                      _target(TourIds.bossEnter, _buildCta())
                    else
                      _buildZoneWarning(),
                  ],
                ),
              ),
            ],
          ),
          if (badge != null)
            Positioned(
              right: 14,
              top: 112,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Color(0xFF1A1004),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  /// The player's side of the duel: avatar, HP bar, recovery.
  Widget _youRow() {
    final max = boss.playerMaxHp;
    final hp = (shownYouHp ?? boss.currentPlayerHp).clamp(0, max);
    final recovery = boss.recoveryEndsAt?.toLocal();
    final recovering =
        hp <= 0 && recovery != null && recovery.isAfter(DateTime.now());
    final frac = max > 0 ? hp / max : 0.0;
    final color = recovering ? const Color(0xFF4D5B6B) : playerHpColor(frac);
    final status = recovering
        ? 'Recovering · ${_fmtDuration(recovery.difference(DateTime.now()))}'
        : '$hp / $max';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          KeyedSubtree(
            key: avatarKey,
            child: LeaderboardAvatar(
                avatarEmoji: avatarEmoji, size: 40, border: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      recovering ? 'Knocked out' : 'You',
                      style: TextStyle(
                        color: recovering ? AppColors.red : AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _PlayerHpBar(frac: frac, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsLine() {
    final blocks = (boss.playerMitigation * 100).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Boss ATK ${boss.counterattackDamage} · your Defense blocks $blocks%',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
          ),
        ),
        Text(
          'Armor ${boss.armor}',
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildCta() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppColors.red, AppColors.redDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onEnterBattle,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                '\u2694\uFE0F Enter Battle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('\uD83D\uDDFA\uFE0F', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              boss.nodeName.isNotEmpty || boss.regionDisplay.isNotEmpty
                  ? 'Travel to ${boss.nodeName.isNotEmpty ? boss.nodeName : boss.regionDisplay} to fight'
                  : 'Travel to this boss zone to fight',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  static String _fmtNumber(int n) {
    if (n >= 1000)
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return n.toString();
  }
}

/// Green bar for the player's HP; a pale trail follows a drop a beat later.
class _PlayerHpBar extends StatelessWidget {
  final double frac;
  final Color color;
  const _PlayerHpBar({required this.frac, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A12),
        borderRadius: BorderRadius.circular(5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: frac.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1200),
          curve: const Interval(.35, 1, curve: Curves.easeOutCubic),
          builder: (_, v, __) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v,
            child: Container(color: Colors.white.withValues(alpha: .5)),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(end: frac.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
