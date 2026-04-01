import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/title_models.dart';

class TitleListItem extends StatelessWidget {
  final TitleDto title;
  final VoidCallback? onEquip;
  final bool isLocked;

  const TitleListItem({
    super.key,
    required this.title,
    this.onEquip,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: title.isEquipped
              ? AppColors.orange.withOpacity(0.6)
              : AppColors.border,
          width: title.isEquipped ? 1.5 : 1.0,
        ),
        boxShadow: title.isEquipped
            ? [
                BoxShadow(
                  color: AppColors.orange.withOpacity(0.12),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Emoji container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: title.isEquipped
                  ? AppColors.orange.withOpacity(0.15)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                title.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Title name + unlock condition
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (title.isEquipped) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: const Text(
                          'EQUIPPED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title.unlockCondition,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right action: equip button or lock icon
          if (isLocked)
            const Icon(
              Icons.lock_outline,
              size: 18,
              color: AppColors.textSecondary,
            )
          else if (!title.isEquipped)
            TextButton(
              onPressed: onEquip,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Equip',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                ),
              ),
            ),
        ],
      ),
    );

    if (isLocked) {
      return Opacity(opacity: 0.5, child: card);
    }
    return card;
  }
}
