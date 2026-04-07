import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/boss_list_item.dart';

class BossLockedCard extends StatelessWidget {
  final BossListItem boss;

  const BossLockedCard({super.key, required this.boss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ── Top row ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Greyscale avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.saturation,
                    ),
                    child: Opacity(
                      opacity: 0.6,
                      child: Text(boss.icon, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
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
                          color: Color(0xFF586070),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${boss.regionDisplay} \u00B7 Level ${boss.levelRequirement}',
                        style: const TextStyle(
                          color: Color(0xFF3d444d),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Lock icon + info
                Column(
                  children: [
                    const Text('\uD83D\uDD12', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      'Lvl ${boss.levelRequirement}',
                      style: const TextStyle(
                        color: Color(0xFF586070),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Progress bar section ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Level progress',
                      style: TextStyle(color: Color(0xFF586070), fontSize: 10),
                    ),
                    Text(
                      'Reach level ${boss.levelRequirement}',
                      style: const TextStyle(color: Color(0xFF586070), fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e2632),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0, // unknown without user level
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF30363d), Color(0xFF586070)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
