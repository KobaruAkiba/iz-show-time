import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/user_data_store.dart';
import '../../l10n/l10n.dart';
import 'notification_permission_preprompt.dart';

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

  Future<void> initialize({
    UserDataStore? userDataStore,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    if (_initialized) return;

    final l10n = AppL10n.current;
    // Delay Darwin permission prompts until after the in-app rationale.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final initSettings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwinSettings,
      macOS: darwinSettings,
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
    unawaited(
      _requestPermissions(
        userDataStore: userDataStore,
        navigatorKey: navigatorKey,
      ),
    );
  }

  Future<void> _requestPermissions({
    UserDataStore? userDataStore,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macOs = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    if (android == null && ios == null && macOs == null) return;

    if (await _notificationsAlreadyEnabled(
      android: android,
      ios: ios,
      macOs: macOs,
    )) {
      return;
    }

    if (userDataStore != null && navigatorKey != null) {
      final proceed = await showNotificationPermissionPrePrompt(
        userDataStore: userDataStore,
        navigatorKey: navigatorKey,
      );
      if (!proceed) return;
    }

    if (android != null) {
      await android.requestNotificationsPermission();
      return;
    }

    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }

    await macOs!.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<bool> _notificationsAlreadyEnabled({
    AndroidFlutterLocalNotificationsPlugin? android,
    IOSFlutterLocalNotificationsPlugin? ios,
    MacOSFlutterLocalNotificationsPlugin? macOs,
  }) async {
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    if (ios != null) {
      final options = await ios.checkPermissions();
      return options?.isEnabled ?? false;
    }

    if (macOs != null) {
      final options = await macOs.checkPermissions();
      return options?.isEnabled ?? false;
    }

    return false;
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
