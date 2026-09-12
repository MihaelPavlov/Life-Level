import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../character/models/character_profile.dart';

/// Combat readout for the Gear page: Power alongside Attack / HP / Defense.
/// (Coins stays as its own pill at the top of the page.) All four values are
/// computed server-side (`CombatStatsCalculator`, from core stats + equipped
/// gear + talents) and returned on `CharacterProfile` — this widget is pure
/// display, no client-side formula.
class GearStatsRow extends StatelessWidget {
  final CharacterProfile profile;
  const GearStatsRow({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CombatStat(
            icon: Image.asset(
              AppIcons.homePowerIcon,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.bolt_rounded, size: 18, color: AppColors.orange),
            ),
            value: profile.power,
            valueColor: AppColors.orange,
          ),
          _divider(),
          _CombatStat(
            icon: Image.asset(AppIcons.homeSwordIcon, width: 18, height: 18, fit: BoxFit.contain),
            value: profile.attack,
          ),
          _divider(),
          _CombatStat(
            icon: const Icon(Icons.favorite_rounded, size: 18, color: AppColors.red),
            value: profile.health,
          ),
          _divider(),
          _CombatStat(
            icon: const Icon(Icons.shield_rounded, size: 18, color: AppColors.blue),
            value: profile.defense,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 26, color: Colors.white.withValues(alpha: 0.12));
}

class _CombatStat extends StatelessWidget {
  final Widget icon;
  final int value;
  final Color? valueColor;
  const _CombatStat({required this.icon, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
