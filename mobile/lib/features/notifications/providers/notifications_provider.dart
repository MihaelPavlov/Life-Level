import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notifications_service.dart';

/// Riverpod access point for [NotificationsService].
///
/// The service itself is a singleton — this provider exposes it so other
/// features (e.g. auth logout flow) can read it via `ref.read` without
/// importing the service directly.
final notificationsServiceProvider = Provider<NotificationsService>(
  (ref) => NotificationsService.instance,
);
