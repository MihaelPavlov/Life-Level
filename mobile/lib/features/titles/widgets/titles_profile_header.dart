import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../character/models/character_profile.dart';
import '../models/title_models.dart';

class TitlesProfileHeader extends StatelessWidget {
  final TitlesAndRanksResponse data;
  final CharacterProfile profile;
  final VoidCallback? onChangeTitleTap;

  const TitlesProfileHeader({
    super.key,
    required this.data,
    required this.profile,
    this.onChangeTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle =
        data.activeTitleEmoji.isNotEmpty && data.activeTitleName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          // Avatar circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.purple.withOpacity(0.35),
                  AppColors.blue.withOpacity(0.12),
                ],
              ),
              border: Border.all(
                color: AppColors.purple.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withOpacity(0.25),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile.avatarEmoji ?? '🧙',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Username
          Text(
            profile.username,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Active title badge or fallback
          if (hasTitle)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.orange.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                '${data.activeTitleEmoji} ${data.activeTitleName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
            )
          else
            Text(
              'No title equipped',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

          const SizedBox(height: 8),

          // Level & XP subtext
          Text(
            'Lv.${profile.level}  \u2022  ${profile.xp} XP',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 4),

          // Change active title button
          TextButton(
            onPressed: onChangeTitleTap,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '\u270f\ufe0f Change Active Title',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
