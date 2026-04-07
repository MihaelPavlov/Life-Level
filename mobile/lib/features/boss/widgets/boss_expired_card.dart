import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/boss_list_item.dart';
import 'boss_hp_bar.dart';

class BossExpiredCard extends StatelessWidget {
  final BossListItem boss;

  const BossExpiredCard({super.key, required this.boss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar with expired overlay
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: 0.5,
                        child: Text(boss.icon,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.orange,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.timer_off_rounded,
                            size: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boss.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${boss.regionDisplay} \u00B7 ${boss.isMini ? "Mini Boss" : "Boss"}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    border:
                        Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'EXPIRED',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // HP bar showing how far they got
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: BossHpBar(
                hpDealt: boss.hpDealt, maxHp: boss.maxHp, showLabel: true, height: 8),
          ),
          // Footer message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Text(
              'Time ran out \u2014 dealt ${_fmtNumber(boss.hpDealt)} / ${_fmtNumber(boss.maxHp)} damage',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.orange.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}
