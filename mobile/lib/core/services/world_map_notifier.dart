import 'dart:async';

import 'package:flutter/foundation.dart';

typedef ZonePick = ({String zoneId, String zoneName});

class WorldMapOpenRequest {
  final ValueChanged<ZonePick>? onZoneSelected;
  final bool autoOpenActiveRegion;
  final String? regionId;
  final String? zoneId;
  const WorldMapOpenRequest({
    this.onZoneSelected,
    this.autoOpenActiveRegion = false,
    this.regionId,
    this.zoneId,
  });
}

class WorldMapNotifier {
  WorldMapNotifier._();

  static final _controller = StreamController<WorldMapOpenRequest>.broadcast();

  static Stream<WorldMapOpenRequest> get stream => _controller.stream;

  static void open({
    ValueChanged<ZonePick>? onZoneSelected,
    bool autoOpenActiveRegion = false,
    String? regionId,
    String? zoneId,
  }) =>
      _controller.add(WorldMapOpenRequest(
        onZoneSelected: onZoneSelected,
        autoOpenActiveRegion: autoOpenActiveRegion,
        regionId: regionId,
        zoneId: zoneId,
      ));
}
