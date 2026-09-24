import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/season_models.dart';
import 'season_theme.dart';

class SeasonMilestoneCard extends StatelessWidget {
  final SeasonTier tier;
  const SeasonMilestoneCard({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    // Prefer the Founder reward for the finale headline; fall back to Free.
    final r = tier.founder.type == 'None' ? tier.free : tier.founder;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3a2a52)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withValues(alpha: 0.16),
            AppColors.orange.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            seasonIconAsset(r.iconKey),
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events_rounded,
                size: 40, color: AppColors.purple),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TIER ${tier.tier} · SEASON FINALE',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  r.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Carries between seasons',
                  style:
                      TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
