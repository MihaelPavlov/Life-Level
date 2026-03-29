import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class QuestEmptyState extends StatelessWidget {
  final String message;

  const QuestEmptyState(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📜', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'No Quests Available',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
