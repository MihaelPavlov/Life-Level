import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/notification_list_models.dart';

/// One row inside the bell sheet. Matches `.home3-notif` in home-v3.html.
class NotificationRow extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const NotificationRow({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, glyph) = _styleFor(item.category);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread indicator (small blue dot)
            SizedBox(
              width: 10,
              child: !item.isRead
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: 0.8),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            // Icon pill
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(glyph, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(item.createdAt),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color bg, Color border, String glyph) _styleFor(
    NotificationCategory c,
  ) {
    switch (c) {
      case NotificationCategory.storm:
        return (
          AppColors.orange.withValues(alpha: 0.12),
          AppColors.orange.withValues(alpha: 0.4),
          '\u26A1', // ⚡
        );
      case NotificationCategory.boss:
        return (
          AppColors.red.withValues(alpha: 0.12),
          AppColors.red.withValues(alpha: 0.4),
          '\u2694\uFE0F', // ⚔️
        );
      case NotificationCategory.guild:
        return (
          AppColors.purple.withValues(alpha: 0.12),
          AppColors.purple.withValues(alpha: 0.4),
          '\uD83D\uDEE1', // 🛡
        );
      case NotificationCategory.quest:
        return (
          AppColors.blue.withValues(alpha: 0.1),
          AppColors.blue.withValues(alpha: 0.35),
          '\u23F3', // ⏳
        );
      case NotificationCategory.social:
        return (
          AppColors.green.withValues(alpha: 0.12),
          AppColors.green.withValues(alpha: 0.35),
          '\uD83C\uDFC6', // 🏆
        );
    }
  }

  static String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes} MIN AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    if (diff.inDays < 7) return '${diff.inDays}D AGO';
    return '${at.day}/${at.month}';
  }
}
