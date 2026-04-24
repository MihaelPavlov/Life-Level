import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/dungeon_floor_cleared_notifier.dart';
import '../../../core/services/world_zone_refresh_notifier.dart';
import '../../../core/widgets/api_error_state.dart';
import '../models/world_map_models.dart';
import '../services/world_zone_service.dart';

/// Bottom sheet shown when the user taps `⚔️ Enter dungeon` / `Return`
/// on a dungeon zone. Renders the full floor list inline over the region
/// detail screen — no navigation, no new page.
///
/// Subscribes to [DungeonFloorClearedNotifier] so floor status auto-refreshes
/// while the sheet is open (e.g. user logs an activity from elsewhere and the
/// active floor clears in-place).
class DungeonFloorsSheet extends StatefulWidget {
  final String zoneId;

  /// Called after the sheet dismisses so the caller can reload the region
  /// detail (floor counts on the zone bubble may have changed).
  final VoidCallback? onDismiss;

  const DungeonFloorsSheet({
    super.key,
    required this.zoneId,
    this.onDismiss,
  });

  @override
  State<DungeonFloorsSheet> createState() => _DungeonFloorsSheetState();
}

class _DungeonFloorsSheetState extends State<DungeonFloorsSheet> {
  final _service = WorldZoneService();
  late final StreamSubscription<DungeonFloorClearedEvent> _floorSub;
  late final StreamSubscription<void> _refreshSub;

  DungeonState? _state;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _floorSub = DungeonFloorClearedNotifier.stream.listen((_) => _load());
    _refreshSub = WorldZoneRefreshNotifier.stream.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _floorSub.cancel();
    _refreshSub.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = _state == null;
      _error = null;
    });
    try {
      final state = await _service.getDungeonState(widget.zoneId);
      if (!mounted) return;
      setState(() {
        _state = state;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: Color(0x8C000000),
                blurRadius: 40,
                offset: Offset(0, -18),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.purple,
                            strokeWidth: 2,
                          ),
                        )
                      : _error != null
                          ? ApiErrorState(
                              title: 'Failed to load dungeon',
                              message: _error!,
                              onRetry: _load,
                            )
                          : _buildContent(scrollController, _state!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController controller, DungeonState state) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        _Header(state: state),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            'TRIAL PROGRESS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        for (final floor in state.floors) _FloorCard(floor: floor),
        if (state.status == DungeonRunStatus.inProgress)
          const _ForfeitHint(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DungeonState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.totalFloors;
    final current = state.currentFloorOrdinal.clamp(1, total);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.14),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('🏚️', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.zoneName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(state, current, total),
                style: TextStyle(
                  color: _subtitleColor(state.status),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _subtitle(DungeonState state, int current, int total) {
    switch (state.status) {
      case DungeonRunStatus.inProgress:
        return 'FLOOR $current OF $total · +${state.bonusXp} XP ON CLEAR';
      case DungeonRunStatus.completed:
        return '✓ CLEARED · +${state.bonusXp} XP AWARDED';
      case DungeonRunStatus.abandoned:
        final lost = state.floors
            .where((f) => f.status == DungeonFloorStatus.forfeited)
            .length;
        return '✕ ABANDONED · $lost/$total LOST';
      case DungeonRunStatus.notEntered:
        return '$total FLOORS · +${state.bonusXp} XP ON CLEAR';
    }
  }

  Color _subtitleColor(DungeonRunStatus s) {
    switch (s) {
      case DungeonRunStatus.completed:
        return AppColors.green;
      case DungeonRunStatus.abandoned:
        return AppColors.red;
      default:
        return AppColors.purple;
    }
  }
}

class _FloorCard extends StatelessWidget {
  final DungeonFloor floor;
  const _FloorCard({required this.floor});

  @override
  Widget build(BuildContext context) {
    final isActive = floor.status == DungeonFloorStatus.active;
    final isDone = floor.status == DungeonFloorStatus.completed;
    final isForfeit = floor.status == DungeonFloorStatus.forfeited;
    final isLocked = floor.status == DungeonFloorStatus.locked;

    final borderColor = isActive
        ? AppColors.orange.withValues(alpha: 0.5)
        : isDone
            ? AppColors.green.withValues(alpha: 0.45)
            : isForfeit
                ? AppColors.red.withValues(alpha: 0.4)
                : AppColors.border;
    final bg = isActive
        ? AppColors.orange.withValues(alpha: 0.06)
        : AppColors.surfaceElevated;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(floor.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Floor ${floor.ordinal} · ${floor.activityType}',
                        style: TextStyle(
                          color: isForfeit
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          decoration: isForfeit
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subLabel(floor),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _FloorPill(status: floor.status),
              ],
            ),
            if (isActive || isDone) ...[
              const SizedBox(height: 10),
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(3),
                ),
                clipBehavior: Clip.hardEdge,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: floor.progressFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.green : AppColors.orange,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subLabel(DungeonFloor f) {
    final unit = f.targetKind == DungeonFloorTargetKind.distanceKm
        ? 'km'
        : 'minutes';
    if (f.status == DungeonFloorStatus.forfeited) return 'Forfeited';
    if (f.status == DungeonFloorStatus.locked) {
      return '${_fmt(f.targetValue)} $unit · locked';
    }
    return '${_fmt(f.progressValue)} / ${_fmt(f.targetValue)} $unit';
  }

  String _fmt(double v) =>
      v.truncateToDouble() == v ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _FloorPill extends StatelessWidget {
  final DungeonFloorStatus status;
  const _FloorPill({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (status) {
      case DungeonFloorStatus.completed:
        label = '✓ DONE';
        color = AppColors.green;
        break;
      case DungeonFloorStatus.active:
        label = '⚡ ACTIVE';
        color = AppColors.orange;
        break;
      case DungeonFloorStatus.forfeited:
        label = '✕ LOST';
        color = AppColors.red;
        break;
      case DungeonFloorStatus.locked:
        label = '🔒 LOCKED';
        color = AppColors.textMuted;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ForfeitHint extends StatelessWidget {
  const _ForfeitHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Setting a destination past this dungeon will forfeit remaining floors · permanent',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.red,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
