import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'map_colors.dart';
import 'models/map_models.dart';

// ── MapPill ───────────────────────────────────────────────────────────────────
class MapPill extends StatelessWidget {
  final String label;
  final Color color;
  const MapPill(this.label, {super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4), width: 1),
    ),
    child: Text(label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

// ── MapSectionLabel ───────────────────────────────────────────────────────────
class MapSectionLabel extends StatelessWidget {
  final String text;
  const MapSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: AppColors.textSecondary,
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8));
}

// ── MapInfoRow ────────────────────────────────────────────────────────────────
class MapInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const MapInfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ── MapInfoChip ───────────────────────────────────────────────────────────────
class MapInfoChip extends StatelessWidget {
  final String text;
  const MapInfoChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: kMapSurface2, borderRadius: BorderRadius.circular(6),
      border: Border.all(color: kMapBorder),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
  );
}

// ── DungeonFloorRow ───────────────────────────────────────────────────────────
class DungeonFloorRow extends StatelessWidget {
  final DungeonFloorData floor;
  final bool isCompleted;
  final bool isNext;
  final bool isBusy;
  final VoidCallback? onComplete;

  const DungeonFloorRow({
    super.key,
    required this.floor,
    required this.isCompleted,
    required this.isNext,
    required this.isBusy,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.green
        : isNext
            ? AppColors.purple
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.green.withOpacity(0.08)
              : isNext
                  ? AppColors.purple.withOpacity(0.08)
                  : const Color(0xFF1e2632),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted
                ? AppColors.green.withOpacity(0.3)
                : isNext
                    ? AppColors.purple.withOpacity(0.4)
                    : const Color(0xFF30363d),
          ),
        ),
        child: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Center(child: isCompleted
                ? Icon(Icons.check, color: color, size: 13)
                : Text('${floor.floorNumber}',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Floor ${floor.floorNumber}',
                style: TextStyle(color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${floor.requiredActivity} · ${floor.requiredMinutes} min',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          )),
          Text('⚡ ${floor.rewardXp}',
            style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
          if (onComplete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isBusy ? null : onComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.purple.withOpacity(0.5)),
                ),
                child: isBusy
                    ? const SizedBox(width: 12, height: 12,
                        child: CircularProgressIndicator(color: AppColors.purple, strokeWidth: 1.5))
                    : const Text('Complete',
                        style: TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── SelectablePathCard ────────────────────────────────────────────────────────
class SelectablePathCard extends StatelessWidget {
  final CrossroadsPathData path;
  final bool isChosen;
  final bool isDisabled;
  final bool canChoose;
  final VoidCallback? onTap;

  const SelectablePathCard({
    super.key,
    required this.path,
    required this.isChosen,
    required this.isDisabled,
    required this.canChoose,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = mapDifficultyColor(path.difficulty);
    final borderColor = isChosen
        ? AppColors.orange
        : canChoose
            ? diffColor.withOpacity(0.4)
            : kMapBorder;
    final bgColor = isChosen
        ? AppColors.orange.withOpacity(0.1)
        : isDisabled
            ? kMapSurface2.withOpacity(0.4)
            : canChoose
                ? diffColor.withOpacity(0.05)
                : kMapSurface2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isChosen ? 1.5 : 1,
          ),
        ),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(path.name,
                  style: TextStyle(
                    color: isChosen ? AppColors.orange : AppColors.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w700),
                )),
                if (isChosen)
                  const Text('✓', style: TextStyle(color: AppColors.orange, fontSize: 16, fontWeight: FontWeight.w700)),
                if (canChoose)
                  Icon(Icons.chevron_right, color: diffColor.withOpacity(0.6), size: 18),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: [
                MapPill(path.difficulty, color: diffColor),
                MapInfoChip('${path.distanceKm.toStringAsFixed(0)} km · ${path.estimatedDays}d'),
                MapInfoChip('⚡ ${path.rewardXp} XP'),
              ]),
              if (path.additionalRequirement != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 11)),
                  Expanded(child: Text(path.additionalRequirement!,
                    style: const TextStyle(color: AppColors.red, fontSize: 11))),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
