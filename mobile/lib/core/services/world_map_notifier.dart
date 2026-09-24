import 'dart:async';

import 'package:flutter/foundation.dart';

typedef ZonePick = ({String zoneId, String zoneName});

class WorldMapOpenRequest {
  final ValueChanged<ZonePick>? onZoneSelected;
  final bool autoOpenActiveRegion;
  const WorldMapOpenRequest({
    this.onZoneSelected,
    this.autoOpenActiveRegion = false,
  });
}

class WorldMapNotifier {
  WorldMapNotifier._();

  static final _controller = StreamController<WorldMapOpenRequest>.broadcast();

  static Stream<WorldMapOpenRequest> get stream => _controller.stream;

  static void open({
    ValueChanged<ZonePick>? onZoneSelected,
    bool autoOpenActiveRegion = false,
  }) =>
      _controller.add(WorldMapOpenRequest(
        onZoneSelected: onZoneSelected,
        autoOpenActiveRegion: autoOpenActiveRegion,
      ));
}
