import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../session/invalidate_user_providers.dart';

/// Shared error view for API failures. Shows a message, a Retry button, and
/// a Logout button — the latter is the escape hatch when the user is stuck
/// with a bad session (stale JWT, deleted user, etc.) and no amount of
/// retrying will fix it.
class ApiErrorState extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback onRetry;

  const ApiErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Something went wrong',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (title != null) const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => performLogout(context),
                  icon: const Icon(Icons.logout, size: 16, color: AppColors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
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
