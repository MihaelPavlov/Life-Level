import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';

/// Pinned "Traveling to X" strip shown at the top of the world hub when the
/// user has an active destination set. Mirrors `.wv3-strip` from the mockup.
class ActiveJourneyBanner extends StatelessWidget {
  final ActiveJourney journey;
  const ActiveJourneyBanner({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final percent = (journey.progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x264f9eff), Color(0x1aa371f7)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.1),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue.withOpacity(0.4)),
                ),
                child: Text(
                  journey.destinationZoneEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRAVELING · ${journey.regionName.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '→ ${journey.destinationZoneName} · ${_fmtKm(journey.distanceTravelledKm)} / ${_fmtKm(journey.distanceTotalKm)} km',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(3),
            ),
            clipBehavior: Clip.hardEdge,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: journey.progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue, AppColors.orange],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          if (journey.arrivalXpReward > 0 ||
              (journey.arrivalBonusLabel?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (journey.arrivalXpReward > 0)
                  _chip('+${journey.arrivalXpReward} XP on arrival',
                      AppColors.orange),
                if (journey.arrivalBonusLabel != null &&
                    journey.arrivalBonusLabel!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _chip(journey.arrivalBonusLabel!, AppColors.purple),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtKm(double km) {
    if (km >= 100) return km.toStringAsFixed(0);
    return km.toStringAsFixed(1);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
