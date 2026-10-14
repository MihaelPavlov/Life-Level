import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/world_zone_service.dart';

final worldZoneServiceProvider =
    Provider<WorldZoneService>((ref) => WorldZoneService());
