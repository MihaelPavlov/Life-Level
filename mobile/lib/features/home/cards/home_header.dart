import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../character/models/character_profile.dart';
import '../../notifications/providers/notification_list_provider.dart';
import '../../notifications/widgets/notifications_sheet.dart';
import '../widgets/home_avatar_ring.dart';
import '../widgets/home_bell_button.dart';
import '../widgets/home_streak_chip.dart';

/// Compact home header: avatar ring + greeting + streak chip + bell.
/// Matches `.home3-header` in home-v3.html (screens 1–4).
class HomeHeader extends ConsumerWidget {
  final CharacterProfile? profile;

  const HomeHeader({super.key, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile;
    final unread = ref.watch(notificationUnreadCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HomeAvatarRing(
            emoji: p?.avatarEmoji ?? '\uD83E\uDDD9', // 🧙
            level: p?.level ?? 1,
            xpProgress: p?.xpProgress ?? 0.0,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greetingFor(DateTime.now().hour),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p?.username ?? '…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                HomeStreakChip(streakDays: p?.currentStreak ?? 0),
              ],
            ),
          ),
          HomeBellButton(
            unreadCount: unread,
            onTap: () => showNotificationsSheet(context),
          ),
        ],
      ),
    );
  }

  String _greetingFor(int hour) {
    if (hour < 5) return 'Good night \uD83C\uDF19';
    if (hour < 12) return 'Good morning \uD83D\uDC4B';
    if (hour < 18) return 'Good afternoon \uD83D\uDC4B';
    return 'Good evening \uD83D\uDC4B';
  }
}
