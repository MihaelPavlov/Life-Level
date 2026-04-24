import 'dart:async';

/// Fired by `log_activity_screen` whenever an activity-log response carries a
/// non-null `floorCreditResult`. Consumed by:
///  - `main_shell.dart` (global toast)
///  - `dungeon_overlay_screen.dart` (animate cleared card + auto-refresh)
class DungeonFloorClearedEvent {
  final String dungeonName;
  final int clearedFloorOrdinal;
  final int totalFloors;
  final bool runCompleted;
  final int bonusXpAwarded;

  const DungeonFloorClearedEvent({
    required this.dungeonName,
    required this.clearedFloorOrdinal,
    required this.totalFloors,
    required this.runCompleted,
    required this.bonusXpAwarded,
  });

  factory DungeonFloorClearedEvent.fromJson(Map<String, dynamic> json) =>
      DungeonFloorClearedEvent(
        dungeonName: json['dungeonName'] as String? ?? '',
        clearedFloorOrdinal:
            (json['clearedFloorOrdinal'] as num?)?.toInt() ?? 0,
        totalFloors: (json['totalFloors'] as num?)?.toInt() ?? 0,
        runCompleted: json['runCompleted'] as bool? ?? false,
        bonusXpAwarded: (json['bonusXpAwarded'] as num?)?.toInt() ?? 0,
      );
}

class DungeonFloorClearedNotifier {
  DungeonFloorClearedNotifier._();
  static final StreamController<DungeonFloorClearedEvent> _controller =
      StreamController<DungeonFloorClearedEvent>.broadcast();
  static Stream<DungeonFloorClearedEvent> get stream => _controller.stream;
  static void notify(DungeonFloorClearedEvent e) => _controller.add(e);
}
