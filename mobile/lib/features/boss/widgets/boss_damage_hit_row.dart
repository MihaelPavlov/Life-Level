import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/boss_damage_history.dart';

/// One row in the RECENT HITS list on the boss battle screen — one logged
/// activity + the damage it dealt. Mirrors the visual density of the
/// existing boss list card (compact, red-tinted), not the big activity
/// history row so it fits inside the battle scaffold.
class BossDamageHitRow extends StatelessWidget {
  final BossDamageHistoryItem hit;
  const BossDamageHitRow({super.key, required this.hit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.red.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          // Emoji tile
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red.withValues(alpha: 0.12),
              border:
                  Border.all(color: AppColors.red.withValues(alpha: 0.35)),
            ),
            child: Text(hit.activityEmoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          // Summary + timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hit.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _relativeTime(hit.loggedAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Damage chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.14),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '−${_fmtDamage(hit.damage)} HP',
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDamage(int n) {
    if (n >= 1000) {
      final v = n / 1000.0;
      return '${v.toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }

  static String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? "" : "s"} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d day${d == 1 ? "" : "s"} ago';
    }
    return '${when.month}/${when.day}';
  }
}
