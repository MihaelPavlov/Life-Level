import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../activity_service.dart';

final activityServiceProvider =
    Provider<ActivityService>((ref) => ActivityService());
