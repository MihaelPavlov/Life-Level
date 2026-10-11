import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../onboarding/widgets/activity_visuals.dart';
import '../models/boss_damage_history.dart';

/// One row in the boss battle screen's RECENT HITS and in the full damage
/// history: one logged activity and the damage it dealt.
///
/// In the history, pass [expanded] (and [onTap]) to make the row open into
/// the hit's maths: raw damage × power multiplier − boss armor, how hard
/// the boss hit back and the HP left after.
class BossDamageHitRow extends StatelessWidget {
  final BossDamageHistoryItem hit;

  /// Null: a plain row. True/false: an expandable history row.
  final bool? expanded;
  final VoidCallback? onTap;

  const BossDamageHitRow(
      {super.key, required this.hit, this.expanded, this.onTap});

  bool get _skipped => hit.skipReason != null;

  @override
  Widget build(BuildContext context) {
    final color = activityColor(hit.activityType);
    final open = expanded == true && !_skipped;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Image.asset(activityIcon(hit.activityType),
                fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
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
                  _skipped
                      ? '${_relativeTime(hit.loggedAt)} · Recovering, attack skipped'
                      : '${_relativeTime(hit.loggedAt)} · Took ${hit.damageTaken} HP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: (_skipped ? AppColors.textSecondary : AppColors.red)
                  .withValues(alpha: 0.14),
              border: Border.all(
                  color: (_skipped ? AppColors.textSecondary : AppColors.red)
                      .withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _skipped ? 'SKIPPED' : '−${_fmtDamage(hit.damage)} HP',
              style: TextStyle(
                color: _skipped ? AppColors.textSecondary : AppColors.red,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (expanded != null) ...[
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: open ? .25 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: _skipped
                      ? Colors.transparent
                      : AppColors.textMuted),
            ),
          ],
        ],
      ),
    );

    if (expanded == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.red.withValues(alpha: 0.08)),
          ),
        ),
        child: row,
      );
    }

    return Material(
      color: open ? Colors.white.withValues(alpha: .035) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _skipped ? null : onTap,
        child: Column(
          children: [
            row,
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: open ? _breakdown() : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdown() {
    final armor = (hit.bossMitigation * 100).round();
    Widget line(String label, String value,
            {Color labelColor = AppColors.textSecondary,
            Color valueColor = AppColors.textPrimary,
            bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: labelColor,
                        fontSize: 12,
                        fontWeight:
                            strong ? FontWeight.w700 : FontWeight.w500)),
              ),
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 12,
                      fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(62, 0, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111822),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (hit.rawDamage > 0) line('Raw damage', '${hit.rawDamage}'),
          line('Power multiplier', '×${hit.damageMultiplier.toStringAsFixed(2)}'),
          if (armor > 0) line('Boss armor', '−$armor%'),
          const Divider(height: 10, color: Color(0xFF222A35)),
          line('Dealt', '${hit.damage} HP',
              labelColor: const Color(0xFFFF8A84),
              valueColor: AppColors.red,
              strong: true),
          line(
            'He hit back',
            hit.damageBlocked > 0
                ? '${hit.damageTaken} HP (${hit.damageBlocked} blocked)'
                : '${hit.damageTaken} HP',
            labelColor: const Color(0xFF8CC0FF),
          ),
          if (hit.bossMaxHp > 0)
            line('Boss HP after', '${hit.bossHpAfter} / ${hit.bossMaxHp}'),
          if (hit.playerHpAfter > 0)
            line('Your HP after', '${hit.playerHpAfter}'),
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
