import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/boss_list_item.dart';
import 'boss_hp_bar.dart';

class BossActiveCard extends StatelessWidget {
  final BossListItem boss;
  final VoidCallback? onEnterBattle;

  const BossActiveCard({super.key, required this.boss, this.onEnterBattle});

  bool get _canFight => onEnterBattle != null;

  @override
  Widget build(BuildContext context) {
    final remaining = boss.timeRemaining;
    // World-zone bosses suppress the legacy 7-day expiry — backend returns
    // `timerExpiresAt: null` and `timerDays: 0`. Surface that as "no limit"
    // instead of the misleading "0d remaining" the legacy formula prints.
    final hasTimer = remaining != null || boss.timerDays > 0;
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
          border: Border.all(color: AppColors.red.withValues(alpha: 0.5), width: 1.5),
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
        child: Column(
          children: [
            // ── Top row: avatar + info + timer ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  // Boss avatar
                  Container(
                    width: 64,
                    height: 64,
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
                    child: Text(boss.icon, style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          boss.isMini ? '\u26A1 MINI BOSS' : '\u26A0\uFE0F ELITE BOSS',
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
                        const SizedBox(height: 2),
                        Text(
                          '${boss.regionDisplay} \u00B7 Lvl ${boss.levelRequirement}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
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

            // ── Body: HP + damage + CTA ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                children: [
                  BossHpBar(hpDealt: boss.hpDealt, maxHp: boss.maxHp),
                  const SizedBox(height: 14),
                  // My damage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.07),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
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
                  const SizedBox(height: 12),
                  // CTA or zone warning
                  if (_canFight)
                    _buildCta()
                  else
                    _buildZoneWarning(),
                ],
              ),
            ),
          ],
        ),
      ),
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
              'Travel to ${boss.nodeName.isNotEmpty ? boss.nodeName : boss.regionDisplay} to fight',
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
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return n.toString();
  }
}
