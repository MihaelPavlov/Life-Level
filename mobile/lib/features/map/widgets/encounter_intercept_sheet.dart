import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/world_zone_service.dart';

/// Bottom sheet shown when movement is interrupted by a trail encounter.
/// For story/merchant: shows a "continue" button so the player can re-tap
/// the zone to proceed. For blockers: explains they must defeat the NPC first.
class EncounterInterceptSheet extends StatelessWidget {
  final ActiveEncounterResult encounter;
  final String? destinationZoneName;

  const EncounterInterceptSheet({
    super.key,
    required this.encounter,
    this.destinationZoneName,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = encounter.isBlocker ? AppColors.red : AppColors.purple;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top:
              BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.5),
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x50000000), blurRadius: 32, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // NPC icon
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.35), width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    Text(encounter.emoji, style: const TextStyle(fontSize: 38)),
              ),
              const SizedBox(height: 16),
              // Headline
              Text(
                encounter.isBlocker
                    ? 'Path Blocked!'
                    : 'You bumped into someone!',
                style: TextStyle(
                  color: encounter.isBlocker
                      ? AppColors.red
                      : AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // NPC name chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  encounter.name,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Body text
              Text(
                _bodyText(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(
                    encounter.isBlocker ? 'blocked' : 'continue',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: encounter.isBlocker
                        ? AppColors.red.withValues(alpha: 0.15)
                        : AppColors.blue,
                    foregroundColor:
                        encounter.isBlocker ? AppColors.red : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: encounter.isBlocker
                          ? BorderSide(
                              color: AppColors.red.withValues(alpha: 0.45))
                          : BorderSide.none,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    encounter.isBlocker ? 'Got it' : 'Continue',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bodyText() {
    final dest = destinationZoneName != null ? ' to $destinationZoneName' : '';
    if (encounter.isBlocker) {
      return '${encounter.name} is standing in your way$dest.\n\nYou cannot pass until you defeat them!';
    }
    if (encounter.isMerchant) {
      return '${encounter.name} is here with wares to offer.\n\nTap the zone again to continue your journey after you\'re done here.';
    }
    return '${encounter.name} has a tale to share.\n\nTap the zone again to continue after listening.';
  }
}
