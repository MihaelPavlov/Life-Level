import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BossHpBar extends StatelessWidget {
  final int hpDealt;
  final int maxHp;
  final bool showLabel;
  final double height;

  /// While a hit animation plays: the damage level the orange "ember" layer
  /// still covers. It sits behind the red fill and burns down to [hpDealt].
  final int? emberHpDealt;

  const BossHpBar({
    super.key,
    required this.hpDealt,
    required this.maxHp,
    this.showLabel = true,
    this.height = 10,
    this.emberHpDealt,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = maxHp - hpDealt;
    final percent = maxHp > 0 ? remaining / maxHp : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Boss HP',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${_fmt(remaining)} / ${_fmt(maxHp)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1014),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Stack(
              children: [
                if (emberHpDealt != null && maxHp > 0)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        ((maxHp - emberHpDealt!) / maxHp).clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.orange, Color(0xFFFFDD8A)],
                        ),
                        boxShadow: [
                          BoxShadow(color: AppColors.orange, blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.red, Color(0xFFff6b35)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(int n) {
    if (n >= 1000)
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    return n.toString();
  }
}
