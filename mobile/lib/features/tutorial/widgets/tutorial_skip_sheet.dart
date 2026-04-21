import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Confirmation bottom-sheet shown when the user taps "Skip" on any bubble.
/// Returns `true` if the user confirms, `false` / `null` otherwise.
/// Caller (typically the overlay root) dispatches the actual `/skip` call.
///
/// Usage:
/// ```dart
/// final confirmed = await showTutorialSkipSheet(context);
/// if (confirmed == true) await controller.skip();
/// ```
Future<bool?> showTutorialSkipSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _TutorialSkipSheet(),
  );
}

class _TutorialSkipSheet extends StatelessWidget {
  const _TutorialSkipSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.surface, AppColors.surfaceElevated],
            ),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 60,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.4),
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('\u26A0', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Skip tutorial?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'You can replay it anytime from Profile \u2192 Settings \u2192 Tutorials.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: 'CANCEL',
                      onPressed: () => Navigator.of(context).pop(false),
                      variant: _ButtonVariant.cancel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetButton(
                      label: 'SKIP',
                      onPressed: () => Navigator.of(context).pop(true),
                      variant: _ButtonVariant.confirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ButtonVariant { cancel, confirm }

class _SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final _ButtonVariant variant;

  const _SheetButton({
    required this.label,
    required this.onPressed,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirm = variant == _ButtonVariant.confirm;
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: isConfirm
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.red, Color(0xFFb8382f)],
                )
              : null,
          color: isConfirm ? null : AppColors.surfaceElevated,
          border: isConfirm
              ? null
              : Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isConfirm ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
