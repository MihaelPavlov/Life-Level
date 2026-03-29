import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'world_map_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Zone Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class WorldMapDetailSheet extends StatelessWidget {
  const WorldMapDetailSheet({
    super.key,
    required this.zone,
    required this.userLevel,
    required this.onEnter,
  });

  final ZoneData zone;
  final int userLevel;
  final VoidCallback onEnter;

  // ── status display ───────────────────────────────────────────────────────────

  String get _statusLabel {
    switch (zone.status) {
      case ZoneStatus.completed: return 'Completed';
      case ZoneStatus.active:    return 'In Progress';
      case ZoneStatus.available: return 'Available';
      case ZoneStatus.locked:    return 'Locked';
    }
  }

  Color get _statusColor {
    switch (zone.status) {
      case ZoneStatus.completed: return AppColors.green;
      case ZoneStatus.active:    return AppColors.blue;
      case ZoneStatus.available: return AppColors.orange;
      case ZoneStatus.locked:    return AppColors.textSecondary;
    }
  }

  bool get _meetsLevelReq => userLevel >= zone.levelRequirement;
  bool get _canEnter => zone.status != ZoneStatus.locked && !zone.isCrossroads;

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0xFF30363d), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3a4a5a),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon + name row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(zone.icon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zone.region,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _statusColor.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              // Stat chips (non-crossroads only)
              if (!zone.isCrossroads &&
                  zone.nodeCount != null &&
                  zone.totalXp != null &&
                  zone.distanceKm != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(label: '${zone.nodeCount} Nodes', icon: '🗺️'),
                    const SizedBox(width: 8),
                    _StatChip(label: '${zone.totalXp} XP', icon: '⭐'),
                    const SizedBox(width: 8),
                    _StatChip(label: '${zone.distanceKm} km', icon: '📍'),
                  ],
                ),
              ],

              // Description
              if (zone.description != null) ...[
                const SizedBox(height: 14),
                Text(
                  zone.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],

              // Requirements
              const SizedBox(height: 16),
              const Text(
                'REQUIREMENTS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              _RequirementRow(
                label: 'Level ${zone.levelRequirement}+',
                met: _meetsLevelReq,
              ),
              if (zone.isCrossroads) ...[
                const SizedBox(height: 6),
                const _RequirementRow(
                  label: 'Branching point — no entry needed',
                  met: true,
                  isNote: true,
                ),
              ],

              // Buttons
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(
                            color: Color(0xFF30363d), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Close',
                          style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  if (!zone.isCrossroads) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _canEnter ? onEnter : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canEnter
                              ? AppColors.blue
                              : const Color(0xFF2a3340),
                          foregroundColor: _canEnter
                              ? Colors.white
                              : AppColors.textSecondary,
                          disabledBackgroundColor: const Color(0xFF2a3340),
                          disabledForegroundColor: AppColors.textSecondary,
                          elevation: _canEnter ? 4 : 0,
                          shadowColor: _canEnter
                              ? AppColors.blue.withOpacity(0.35)
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _canEnter ? 'Enter Zone →' : 'Zone Locked',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable sub-widgets (private to this file)
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});

  final String label;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF30363d), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    required this.met,
    this.isNote = false,
  });

  final String label;
  final bool met;
  final bool isNote;

  @override
  Widget build(BuildContext context) {
    if (isNote) {
      return Row(
        children: [
          const Icon(Icons.info_outline,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 16,
          color: met ? AppColors.green : AppColors.red,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: met ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
