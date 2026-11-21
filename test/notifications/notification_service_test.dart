import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iz_show_time_tracker/core/notifications/notification_service.dart';

void main() {
  NotificationResponse responseWithId(int? id) => NotificationResponse(
    notificationResponseType: NotificationResponseType.selectedNotification,
    id: id,
  );

  test('recognizes a tap on the new episodes notification', () {
    expect(
      NotificationService.isNewEpisodesResponse(responseWithId(1)),
      isTrue,
    );
    expect(
      NotificationService.isNewEpisodesResponse(responseWithId(2)),
      isFalse,
    );
    expect(
      NotificationService.isNewEpisodesResponse(responseWithId(null)),
      isFalse,
    );
  });
}
