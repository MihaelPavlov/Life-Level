import 'dart:async';

import 'package:flutter/foundation.dart';

typedef ZonePick = ({String zoneId, String zoneName});

class WorldMapOpenRequest {
  final ValueChanged<ZonePick>? onZoneSelected;
  const WorldMapOpenRequest({this.onZoneSelected});
}

class WorldMapNotifier {
  WorldMapNotifier._();

  static final _controller =
      StreamController<WorldMapOpenRequest>.broadcast();

  static Stream<WorldMapOpenRequest> get stream => _controller.stream;

  static void open({ValueChanged<ZonePick>? onZoneSelected}) =>
      _controller.add(WorldMapOpenRequest(onZoneSelected: onZoneSelected));
}
