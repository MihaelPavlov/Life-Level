import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/boss_list_item.dart';

class BossDefeatedCard extends StatelessWidget {
  final BossListItem boss;

  const BossDefeatedCard({super.key, required this.boss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar with checkmark
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withValues(alpha: 0.08),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.4), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: 0.7,
                  child: Text(boss.icon, style: const TextStyle(fontSize: 26)),
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
                    color: AppColors.green,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
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
                  '${boss.regionDisplay} · ${boss.isMini ? "Mini Boss" : "Boss"}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Reward
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'DEFEATED',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+${boss.rewardXp} XP',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
