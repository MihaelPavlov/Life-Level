import 'dart:async';

/// Payload broadcast when a foreground FCM message arrives and the app
/// should show an in-app banner to the user.
class NotificationBannerPayload {
  final String title;
  final String body;

  const NotificationBannerPayload({required this.title, required this.body});
}

/// Global notifier for foreground push notification banners.
///
/// NotificationsService fires this whenever a message arrives while the app
/// is open. MainShell listens and shows an AppToast banner.
class NotificationBannerNotifier {
  NotificationBannerNotifier._();

  static final _controller =
      StreamController<NotificationBannerPayload>.broadcast();

  static Stream<NotificationBannerPayload> get stream => _controller.stream;

  static void notify(String title, String body) =>
      _controller.add(NotificationBannerPayload(title: title, body: body));
}
