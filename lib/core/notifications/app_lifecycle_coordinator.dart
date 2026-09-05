import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/app_services.dart';

/// Tracks whether the app is open in the foreground and reloads alerts on resume.
class AppLifecycleCoordinator with WidgetsBindingObserver {
  AppLifecycleCoordinator({required AppServices appServices})
      : _appServices = appServices;

  final AppServices _appServices;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_persistForegroundState(_isOpenState(AppLifecycleState.resumed)));
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_persistForegroundState(_isOpenState(state)));

    if (state == AppLifecycleState.resumed) {
      _appServices.reloadNewEpisodeAlertsFromStore();
    }
  }

  /// Only [AppLifecycleState.resumed] counts as open.
  bool _isOpenState(AppLifecycleState state) {
    return state == AppLifecycleState.resumed;
  }

  Future<void> _persistForegroundState(bool isOpen) async {
    await _appServices.userDataStore.saveAppInForeground(isOpen);
    await _appServices.userDataStore.flush();
  }
}
