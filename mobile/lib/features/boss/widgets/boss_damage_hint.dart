import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BossDamageHint extends StatelessWidget {
  const BossDamageHint({super.key});

  static const _items = [
    ('🏃', 'Running', 'Calories \u00D7 END', AppColors.blue),
    ('🏋️', 'Gym', 'Calories \u00D7 STR', AppColors.purple),
    ('🚴', 'Cycling', 'Calories \u00D7 END', AppColors.blue),
    ('🧘', 'Yoga', 'Calories \u00D7 FLX', AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22).withValues(alpha: 0.7),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW YOUR DAMAGE IS CALCULATED',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0d1117),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(_items[i].$1, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].$2,
                          style: TextStyle(
                            color: _items[i].$4,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _items[i].$3,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
