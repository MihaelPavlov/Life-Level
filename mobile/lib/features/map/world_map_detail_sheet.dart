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
    this.onEnter,
    this.isAdjacentToCurrentZone = true,
    this.travelProgress,
    this.journeyDestinationName,
    this.journeyDestinationIcon,
    this.journeyKmTraveled,
    this.journeyKmTotal,
    this.journeyProgress,
  });

  final ZoneData zone;
  final int userLevel;
  final VoidCallback? onEnter;
  final bool isAdjacentToCurrentZone;
  final double? travelProgress;

  // Active-journey context (non-null only when a journey is in flight).
  // Used by the destination-tapped progress card and the source-zone
  // "You Are Here" summary row.
  final String? journeyDestinationName;
  final String? journeyDestinationIcon;
  final double? journeyKmTraveled;
  final double? journeyKmTotal;
  final double? journeyProgress;

  bool get _hasActiveJourney =>
      journeyDestinationName != null && journeyKmTotal != null && journeyKmTotal! > 0;

  // ── travel-mode layout gates ─────────────────────────────────────────────
  // Destination-during-travel: the user tapped the zone they're traveling to.
  bool get _isDestinationTravel => zone.isDestination && _hasActiveJourney;
  // Source-during-travel: the user tapped the zone they're currently standing
  // in while a separate journey is in flight.
  bool get _isSourceTravel =>
      zone.status == ZoneStatus.active && !zone.isDestination && _hasActiveJourney;

  // ── status display ───────────────────────────────────────────────────────────

  String get _statusLabel {
    // Traveling-to-this-zone takes priority over the raw zone status.
    if (zone.isDestination) return 'Traveling';
    // Current zone while a journey is in flight — "You Are Here" (green)
    // instead of the generic "In Progress" blue pill.
    if (zone.status == ZoneStatus.active && _hasActiveJourney) return 'You Are Here';
    switch (zone.status) {
      case ZoneStatus.completed: return 'Completed';
      case ZoneStatus.active:    return 'In Progress';
      case ZoneStatus.available: return 'Available';
      case ZoneStatus.locked:    return 'Locked';
    }
  }

  Color get _statusColor {
    if (zone.isDestination) return AppColors.orange;
    if (zone.status == ZoneStatus.active && _hasActiveJourney) return AppColors.green;
    switch (zone.status) {
      case ZoneStatus.completed: return AppColors.green;
      case ZoneStatus.active:    return AppColors.blue;
      case ZoneStatus.available: return AppColors.orange;
      case ZoneStatus.locked:    return AppColors.textSecondary;
    }
  }

  bool get _meetsLevelReq => userLevel >= zone.levelRequirement;

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

              // Stat chips (non-crossroads, non-travel-mode only)
              if (!zone.isCrossroads &&
                  !_isDestinationTravel &&
                  !_isSourceTravel &&
                  zone.nodeCount != null &&
                  zone.totalXp != null &&
                  zone.distanceKm != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(
                      label: zone.completedNodeCount != null
                          ? '${zone.completedNodeCount}/${zone.nodeCount} Nodes'
                          : '${zone.nodeCount} Nodes',
                      icon: '🗺️',
                    ),
                    const SizedBox(width: 8),
                    _StatChip(label: '${zone.totalXp} XP', icon: '⭐'),
                    const SizedBox(width: 8),
                    _StatChip(label: '${zone.distanceKm} km', icon: '📍'),
                  ],
                ),
              ],

              // Description (hidden in source-travel mode — Frame 3 has no description)
              if (!_isSourceTravel && zone.description != null) ...[
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

              // Your Journey (destination-travel mode only)
              if (_isDestinationTravel) ...[
                const SizedBox(height: 16),
                const Text(
                  'YOUR JOURNEY',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                _JourneyProgressCard(
                  destinationName: journeyDestinationName!,
                  progress: journeyProgress ?? 0.0,
                  kmTraveled: journeyKmTraveled ?? 0.0,
                  kmTotal: journeyKmTotal!,
                ),
              ],

              // You Are Here + Current Journey (source-travel mode only)
              if (_isSourceTravel) ...[
                const SizedBox(height: 16),
                _YouAreHereCard(),
                const SizedBox(height: 14),
                const Text(
                  'CURRENT JOURNEY',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                _JourneyDestSummary(
                  destinationName: journeyDestinationName!,
                  destinationIcon: journeyDestinationIcon ?? '🏁',
                  progress: journeyProgress ?? 0.0,
                  kmRemaining: (journeyKmTotal! - (journeyKmTraveled ?? 0.0))
                      .clamp(0.0, journeyKmTotal!),
                ),
              ],

              // Requirements (hidden in source-travel mode)
              if (!_isSourceTravel) ...[
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
                    if (zone.status == ZoneStatus.completed && onEnter != null)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onEnter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green.withOpacity(0.15),
                            foregroundColor: AppColors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppColors.green.withOpacity(0.4)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Revisit Zone →',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      )
                    else if (zone.status == ZoneStatus.completed)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.green, size: 18),
                              const SizedBox(width: 8),
                              Text('Zone Completed',
                                style: TextStyle(color: AppColors.green, fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      )
                    else if (_isDestinationTravel)
                      // Permanently disabled during travel. Auto-arrive flips
                      // state before mobile ever sees 100%, so the enabled
                      // counterpart is unreachable — treat this as progress
                      // copy only. Crucially, onPressed stays null so a tap
                      // cannot re-call SetDestinationAsync (would reset km).
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            disabledBackgroundColor: const Color(0xFF2a3340),
                            disabledForegroundColor: AppColors.textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('🔒 Enter Zone at 100%',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      )
                    else if (_isSourceTravel)
                      // Source zone during an active journey — green "Enter
                      // Local Map" CTA (Frame 3 of the zone-click-progress
                      // mockup). Reuses the same onEnter callback as the
                      // default active-zone path below.
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onEnter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.green.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Enter Local Map →',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      )
                    else if (zone.status == ZoneStatus.active && !zone.isDestination)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onEnter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.blue.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Enter Zone →',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      )
                    else if (zone.status == ZoneStatus.available && !isAdjacentToCurrentZone)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1e2632),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF30363d)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline,
                                  color: AppColors.textSecondary, size: 16),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Travel to an adjacent zone first',
                                  style: TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onEnter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                onEnter != null ? AppColors.blue : const Color(0xFF2a3340),
                            foregroundColor:
                                onEnter != null ? Colors.white : AppColors.textSecondary,
                            disabledBackgroundColor: const Color(0xFF2a3340),
                            disabledForegroundColor: AppColors.textSecondary,
                            elevation: onEnter != null ? 4 : 0,
                            shadowColor: onEnter != null
                                ? AppColors.blue.withOpacity(0.35)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            zone.status == ZoneStatus.available
                                ? 'Set as Destination →'
                                : 'Zone Locked',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                  if (zone.isCrossroads) ...[
                    const SizedBox(width: 12),
                    if (zone.status == ZoneStatus.completed)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.green, size: 18),
                              const SizedBox(width: 8),
                              Text('Crossroads Passed',
                                style: TextStyle(color: AppColors.green, fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      )
                    else if (zone.status == ZoneStatus.active && zone.isDestination)
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.route, color: AppColors.orange, size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: travelProgress ?? 0,
                                        backgroundColor: AppColors.orange.withOpacity(0.15),
                                        valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${((travelProgress ?? 0) * 100).round()}%',
                                    style: const TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (zone.status == ZoneStatus.active && !zone.isDestination)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.my_location, color: AppColors.green, size: 16),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'You are here — tap a zone to continue',
                                  style: TextStyle(
                                      color: AppColors.green, fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (zone.status == ZoneStatus.available && !isAdjacentToCurrentZone)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1e2632),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF30363d)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline,
                                  color: AppColors.textSecondary, size: 16),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Travel to an adjacent zone first',
                                  style: TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: onEnter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                onEnter != null ? AppColors.blue : const Color(0xFF2a3340),
                            foregroundColor:
                                onEnter != null ? Colors.white : AppColors.textSecondary,
                            disabledBackgroundColor: const Color(0xFF2a3340),
                            disabledForegroundColor: AppColors.textSecondary,
                            elevation: onEnter != null ? 4 : 0,
                            shadowColor: onEnter != null
                                ? AppColors.blue.withOpacity(0.35)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            zone.status == ZoneStatus.available
                                ? 'Set as Destination →'
                                : 'Zone Locked',
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

// ─────────────────────────────────────────────────────────────────────────────
// Travel-mode helper widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Prominent progress card shown on the destination-zone sheet while traveling.
/// Frame 2 of design-mockup/map/zone-click-progress.html.
class _JourneyProgressCard extends StatelessWidget {
  const _JourneyProgressCard({
    required this.destinationName,
    required this.progress,
    required this.kmTraveled,
    required this.kmTotal,
  });

  final String destinationName;
  final double progress;
  final double kmTraveled;
  final double kmTotal;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    final remaining = (kmTotal - kmTraveled).clamp(0.0, kmTotal);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.28), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🚶‍♂️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'On the road to $destinationName',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.orange.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.orange),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ProgressFootText(
                primary: '${kmTraveled.toStringAsFixed(1)} km',
                secondary: ' traveled',
              ),
              _ProgressFootText(
                primary: '${remaining.toStringAsFixed(1)} km',
                secondary: ' remaining · of ${kmTotal.toStringAsFixed(0)} km',
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressFootText extends StatelessWidget {
  const _ProgressFootText({
    required this.primary,
    required this.secondary,
    this.alignEnd = false,
  });

  final String primary;
  final String secondary;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: RichText(
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: primary,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: secondary,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green informational card on the source-zone sheet while a separate journey
/// is in flight. Frame 3 of design-mockup/map/zone-click-progress.html.
class _YouAreHereCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "You left this zone — the world is behind you. Tap Enter Local Map to explore this zone's nodes.",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-column summary row on the source-zone sheet: left shows the
/// destination the user is heading to, right shows progress + km remaining.
/// Frame 3 of design-mockup/map/zone-click-progress.html.
class _JourneyDestSummary extends StatelessWidget {
  const _JourneyDestSummary({
    required this.destinationName,
    required this.destinationIcon,
    required this.progress,
    required this.kmRemaining,
  });

  final String destinationName;
  final String destinationIcon;
  final double progress;
  final double kmRemaining;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HEADING TO',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$destinationIcon $destinationName',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'PROGRESS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$pct% · ${kmRemaining.toStringAsFixed(1)} km left',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
