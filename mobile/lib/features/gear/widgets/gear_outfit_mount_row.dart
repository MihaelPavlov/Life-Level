import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';

/// Decorative "Outfit" / "Mount" preview cards. There's no cosmetic outfit or
/// mount system in the domain yet — same static-placeholder precedent as
/// Home's Weapon/Mount mini-cards (`home_hero_stage.dart`). Tapping shows a
/// lightweight "coming soon" toast rather than doing nothing silently.
class GearOutfitMountRow extends StatelessWidget {
  const GearOutfitMountRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PreviewCard(
            iconAsset: AppIcons.gearOutfitIcon,
            label: 'Outfit',
            onTap: () => _showComingSoon(context, 'Outfits'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PreviewCard(
            iconAsset: AppIcons.gearMountIcon,
            label: 'Mount',
            onTap: () => _showComingSoon(context, 'Mounts'),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label are coming soon!')),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  const _PreviewCard({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconAsset, width: 44, height: 44, fit: BoxFit.contain),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
