import 'dart:async';

import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import '../services/app_services.dart';
import 'notification_service.dart';

/// Tracks whether the app is open in the foreground, reloads alerts and
/// clears the stale new episodes notification on resume.
///
/// Only [AppLifecycleState.resumed] counts as open. While resumed, the
/// foreground flag is refreshed periodically: the background check ignores a
/// flag whose heartbeat is stale, so a crash in foreground does not block
/// notifications forever.
class AppLifecycleCoordinator with WidgetsBindingObserver {
  AppLifecycleCoordinator({
    required AppServices appServices,
    Future<void> Function()? clearNewEpisodesNotification,
    Duration heartbeatInterval = AppConstants.appForegroundHeartbeatInterval,
  })  : _appServices = appServices,
        _clearNewEpisodesNotification = clearNewEpisodesNotification ??
            NotificationService().cancelNewEpisodesNotification,
        _heartbeatInterval = heartbeatInterval;

  final AppServices _appServices;
  final Future<void> Function() _clearNewEpisodesNotification;
  final Duration _heartbeatInterval;
  Timer? _heartbeatTimer;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    switch (WidgetsBinding.instance.lifecycleState) {
      case AppLifecycleState.resumed:
        _markOpen();
      case null:
        // No lifecycle event yet: mark the app open once, without a
        // heartbeat. If no real resume follows, the flag expires on its own.
        unawaited(_persistForegroundState(true));
      case _:
        _markClosed();
    }
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _markClosed();
      return;
    }

    _markOpen();
    unawaited(_onResumed());
    unawaited(_clearNewEpisodesNotification());
  }

  /// Network refresh after the import: a slow import must not overwrite the
  /// fresher network result.
  Future<void> _onResumed() async {
    await _appServices.importBackgroundCheckResult();
    await _appServices.refreshOnResume();
  }

  void _markOpen() {
    unawaited(_persistForegroundState(true));
    _heartbeatTimer ??= Timer.periodic(
      _heartbeatInterval,
      (_) => unawaited(_persistForegroundState(true)),
    );
  }

  void _markClosed() {
    _stopHeartbeat();
    unawaited(_persistForegroundState(false));
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _persistForegroundState(bool isOpen) async {
    await _appServices.userDataStore.saveAppInForeground(isOpen);
    await _appServices.userDataStore.flush();
  }
}
