import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Sends local system notifications for newly detected TV episodes.
/// Called only from native background scheduling, not while the app is open.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int _newEpisodesNotificationId = 1;
  static const String _channelId = 'new_episodes';
  static const String _channelName = 'New Episodes';

  Future<void> initialize() async {
    if (_initialized) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: 'Film/TV Tracker',
        appUserModelId: 'com.izshowtime.tracker',
        guid: '6f8d2b1a-4c3e-4a5b-9d0e-1f2a3b4c5d6e',
      ),
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<void> showNewEpisodesNotification({required int count}) async {
    if (!_initialized || count <= 0) return;

    const title = 'New episodes available';
    final body = count == 1
        ? 'A new episode is waiting in your catalogue. Open Home and check New Episodes.'
        : '$count new episodes are available. Open Home and check New Episodes.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Alerts when new TV episodes are detected',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );

    try {
      await _plugin.show(
        id: _newEpisodesNotificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to show new episodes notification: $error\n$stackTrace',
      );
    }
  }
}
