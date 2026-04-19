import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ── Section title row (label + optional trailing action) ──────────────────────
class HomeSectionTitle extends StatelessWidget {
  final String label;
  final Widget? labelTrailing;
  final String? action;
  final Color? actionColor;
  final VoidCallback? onActionTap;

  const HomeSectionTitle({
    super.key,
    required this.label,
    this.labelTrailing,
    this.action,
    this.actionColor,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              if (labelTrailing != null) ...[
                const SizedBox(width: 6),
                labelTrailing!,
              ],
            ],
          ),
          if (action != null)
            onActionTap != null
                ? GestureDetector(
                    onTap: onActionTap,
                    child: Text(
                      action!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: actionColor ?? AppColors.blue,
                      ),
                    ),
                  )
                : Text(
                    action!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: actionColor ?? AppColors.blue,
                    ),
                  ),
        ],
      ),
    );
  }
}

/// Rounded "N / M done" pill that sits next to a section title label.
/// Matches .home3-donechip from the mockup.
class HomeDoneChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool dim;

  const HomeDoneChip({
    super.key,
    required this.label,
    this.color,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: dim
            ? AppColors.surfaceElevated
            : c.withValues(alpha: 0.08),
        border: Border.all(
          color: dim ? AppColors.border : c.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: dim ? AppColors.textSecondary : c,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
