import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../profile/tabs/achievements_tab.dart';

class AchievementsScreen extends StatelessWidget {
  final VoidCallback? onClose;
  const AchievementsScreen({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        onPressed: onClose ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(child: AchievementsTab()),
          ],
        ),
      ),
    );
  }
}
