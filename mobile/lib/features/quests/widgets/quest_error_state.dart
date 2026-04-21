import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/invalidate_user_providers.dart';

class QuestErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const QuestErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Try Again',
                    style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => performLogout(context),
                  icon: const Icon(Icons.logout, size: 16, color: AppColors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
