import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../motion/app_motion.dart';
import 'app_icon_image.dart';

/// Content for the reusable resource-information dialog.
class ResourceInfoData {
  final String name;
  final String? icon;
  final IconData? materialIcon;
  final Color? materialIconColor;
  final String description;
  final String destination;

  const ResourceInfoData({
    required this.name,
    this.icon,
    this.materialIcon,
    this.materialIconColor,
    required this.description,
    required this.destination,
  }) : assert(icon != null || materialIcon != null);
}

/// Shows the compact informational popup used when a resource icon is tapped.
Future<void> showResourceInfoDialog(
  BuildContext context,
  ResourceInfoData info,
) {
  return showAppDialog<void>(
    context: context,
    barrierLabel: 'Dismiss ${info.name} information',
    builder: (_) => Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.blue, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: .22),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue.withValues(alpha: .38),
                        AppColors.surfaceElevated,
                      ],
                    ),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.blue, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.blue.withValues(alpha: .7),
                            width: 2,
                          ),
                        ),
                        child: info.materialIcon != null
                            ? Icon(
                                info.materialIcon,
                                size: 50,
                                color: info.materialIconColor,
                              )
                            : AppIconImage(
                                info.icon!,
                                size: 50,
                                visualScale:
                                    info.icon == AppIcons.rewardXpCrystals
                                        ? 2.25
                                        : 1.12,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: .25),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'REWARD',
                                style: TextStyle(
                                  color: Color(0xFFAED6FF),
                                  fontSize: 9,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  child: Text(
                    info.description,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'USED IN',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            info.destination,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
