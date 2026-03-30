import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../map/services/map_service.dart';
import '../../map/models/map_models.dart';

final mapJourneyProvider = FutureProvider<MapFullData>(
  (ref) => MapService().getFullMap(),
);
