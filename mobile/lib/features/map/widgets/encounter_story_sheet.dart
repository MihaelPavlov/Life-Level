import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/encounter_models.dart';

class StorySheet extends StatelessWidget {
  final TrailEncounterNode encounter;

  const StorySheet({super.key, required this.encounter});

  StoryEncounterData get _data => encounter.story!;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 32, offset: Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPortraitRow(),
                    const SizedBox(height: 10),
                    _buildRewardChips(),
                    const SizedBox(height: 8),
                    _buildDialogueBubble(),
                    const SizedBox(height: 14),
                    const Text(
                      'YOUR RESPONSE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._data.choices.map((c) => _buildChoiceRow(context, c)),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      child: const Text('Pass by in silence · Dismiss'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.purple.withOpacity(0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: AppColors.purple.withOpacity(0.2), blurRadius: 20)
            ],
          ),
          alignment: Alignment.center,
          child: Text(_data.portrait, style: const TextStyle(fontSize: 34)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STORY ENCOUNTER',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              Text(
                _data.npcName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              Text(
                _data.npcTitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRewardChips() {
    return Wrap(
      spacing: 6,
      children: [
        _Chip(label: '📜 Lore Unlocked', color: AppColors.purple),
        _Chip(label: '+${_data.loreXp} XP', color: AppColors.orange),
      ],
    );
  }

  Widget _buildDialogueBubble() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: AppColors.purple.withOpacity(0.25)),
      ),
      child: Text(
        '"${_data.dialogue}"',
        style: const TextStyle(
          color: Color(0xFFc9d1d9),
          fontSize: 13,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _buildChoiceRow(BuildContext context, StoryChoice choice) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You chose: ${choice.rewardLabel}'),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: choice.iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(choice.iconEmoji,
                  style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                choice.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              choice.rewardLabel,
              style: TextStyle(
                color: choice.rewardColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
