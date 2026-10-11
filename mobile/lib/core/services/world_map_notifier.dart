import 'dart:async';

import 'package:flutter/foundation.dart';

typedef ZonePick = ({String zoneId, String zoneName});

class WorldMapOpenRequest {
  final ValueChanged<ZonePick>? onZoneSelected;
  final bool autoOpenActiveRegion;
  final String? regionId;
  final String? zoneId;

  /// Opens the region list (not a region) scrolled to this region.
  final String? scrollToRegionId;
  const WorldMapOpenRequest({
    this.onZoneSelected,
    this.autoOpenActiveRegion = false,
    this.regionId,
    this.zoneId,
    this.scrollToRegionId,
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
    String? scrollToRegionId,
  }) =>
      _controller.add(WorldMapOpenRequest(
        onZoneSelected: onZoneSelected,
        autoOpenActiveRegion: autoOpenActiveRegion,
        regionId: regionId,
        zoneId: zoneId,
        scrollToRegionId: scrollToRegionId,
      ));
}
