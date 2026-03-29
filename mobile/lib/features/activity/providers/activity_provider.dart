import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/activity_service.dart';

final activityServiceProvider =
    Provider<ActivityService>((ref) => ActivityService());
