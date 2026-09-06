import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SeasonLegend extends StatelessWidget {
  const SeasonLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _Item(color: AppColors.textMuted, label: 'Received'),
          _Item(color: AppColors.textSecondary, label: 'Locked'),
          _Item(color: AppColors.orange, label: 'Pending'),
          _Item(color: AppColors.green, label: 'Ready'),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final Color color;
  final String label;
  const _Item({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }
}
