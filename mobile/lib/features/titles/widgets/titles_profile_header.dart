import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/avatar_icons.dart';
import '../../../core/constants/title_rank_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/models/character_profile.dart';
import '../models/title_models.dart';

class TitlesProfileHeader extends StatelessWidget {
  final TitlesAndRanksResponse data;
  final CharacterProfile profile;

  const TitlesProfileHeader({
    super.key,
    required this.data,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle =
        data.activeTitleEmoji.isNotEmpty && data.activeTitleName.isNotEmpty;
    final activeTitleIcon = titleIconAsset(name: data.activeTitleName);
    final avatarAsset = avatarIconAsset(profile.avatarEmoji);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
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
              child: avatarAsset != null
                  ? AppIconImage(
                      avatarAsset,
                      size: 46,
                      visualScale: 1.45,
                    )
                  : Text(
                      profile.avatarEmoji ?? '🧙',
                      style: const TextStyle(fontSize: 32),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.username,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (hasTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
              child: AnimatedSize(
                duration: AppMotion.duration(
                    context, const Duration(milliseconds: 250)),
                curve: Curves.easeOut,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: AppMotion.duration(
                          context, const Duration(milliseconds: 320)),
                      transitionBuilder: (child, a) => ScaleTransition(
                        scale: CurvedAnimation(
                            parent: a, curve: Curves.easeOutBack),
                        child: RotationTransition(
                          turns: Tween(begin: -.25, end: 0.0).animate(a),
                          child: child,
                        ),
                      ),
                      child: activeTitleIcon != null
                          ? Padding(
                              key: ValueKey(activeTitleIcon),
                              padding: const EdgeInsets.only(right: 7),
                              child: AppIconImage(
                                activeTitleIcon,
                                size: 18,
                                visualScale: 1.4,
                              ),
                            )
                          : Padding(
                              key: ValueKey(data.activeTitleEmoji),
                              padding: const EdgeInsets.only(right: 5),
                              child: Text(
                                data.activeTitleEmoji,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                    ),
                    Flexible(
                      child: NameplateSwap(
                        data.activeTitleName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              'No title equipped',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Lv.${profile.level}  •  ${profile.xp} XP',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
