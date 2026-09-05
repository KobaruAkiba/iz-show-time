import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/l10n.dart';

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
  // Channel id bumped so Android applies high importance (immutable after create).
  static const String _channelId = 'new_episodes_v2';

  Future<void> initialize() async {
    if (_initialized) return;

    final l10n = AppL10n.current;
    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: const DarwinInitializationSettings(),
      macOS: const DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: l10n.actionOpen),
      windows: WindowsInitializationSettings(
        appName: l10n.appTitle,
        appUserModelId: 'com.izshowtime.tracker',
        guid: '6f8d2b1a-4c3e-4a5b-9d0e-1f2a3b4c5d6e',
      ),
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
    // Do not await permission prompts before/during early startup.
    unawaited(_requestPermissions());
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      return;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }

    final macOs = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macOs != null) {
      await macOs.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showNewEpisodesNotification({required int count}) async {
    if (!_initialized || count <= 0) return;

    final l10n = AppL10n.current;
    final title = l10n.notificationTitle;
    final body = count == 1
        ? l10n.notificationBodyOne
        : l10n.notificationBodyOther(count);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
      linux: const LinuxNotificationDetails(),
      windows: const WindowsNotificationDetails(),
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
