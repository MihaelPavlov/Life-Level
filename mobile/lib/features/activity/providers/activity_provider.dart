import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_models.dart';
import '../services/activity_service.dart';

final activityServiceProvider =
    Provider<ActivityService>((ref) => ActivityService());

final activityHistoryProvider = FutureProvider<List<ActivityHistoryDto>>(
  (ref) => ref.read(activityServiceProvider).getHistory(),
);
